import 'package:dio/dio.dart';
import 'package:alice_transport/alice_transport.dart';
import 'alice_core.dart';

class AliceDioInterceptor extends Interceptor {
  final Alice alice;

  AliceDioInterceptor({required this.alice});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['alice_start_time'] = DateTime.now();
    options.extra['alice_id'] = DateTime.now().microsecondsSinceEpoch.toString();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['alice_start_time'] as DateTime? ?? DateTime.now();
    final id = response.requestOptions.extra['alice_id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString();
    final duration = DateTime.now().difference(startTime);

    final reqHeaders = <String, String>{};
    response.requestOptions.headers.forEach((k, v) => reqHeaders[k] = v.toString());

    final resHeaders = <String, String>{};
    response.headers.forEach((k, v) => resHeaders[k] = v.join(', '));

    final call = AliceHttpCall(
      id: id,
      timestamp: startTime,
      method: response.requestOptions.method,
      uri: response.requestOptions.uri.toString(),
      headers: reqHeaders,
      body: response.requestOptions.data?.toString(),
      statusCode: response.statusCode,
      responseHeaders: resHeaders,
      responseBody: response.data?.toString(),
      durationMs: duration.inMilliseconds,
      isSuccess: (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300,
    );

    alice.addCall(call);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['alice_start_time'] as DateTime? ?? DateTime.now();
    final id = err.requestOptions.extra['alice_id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString();
    final duration = DateTime.now().difference(startTime);

    final reqHeaders = <String, String>{};
    err.requestOptions.headers.forEach((k, v) => reqHeaders[k] = v.toString());

    final call = AliceHttpCall(
      id: id,
      timestamp: startTime,
      method: err.requestOptions.method,
      uri: err.requestOptions.uri.toString(),
      headers: reqHeaders,
      body: err.requestOptions.data?.toString(),
      statusCode: err.response?.statusCode,
      durationMs: duration.inMilliseconds,
      isSuccess: false,
      error: err.message,
    );

    alice.addCall(call);
    handler.next(err);
  }
}
