import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:alice_transport/alice_transport.dart';
import 'alice_core.dart';

class AliceHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Alice alice;

  AliceHttpClient(this._inner, {required this.alice});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final startTime = DateTime.now();

    String? requestBody;
    if (request is http.Request) {
      requestBody = request.body;
    }

    try {
      final response = await _inner.send(request);
      final responseBytes = await response.stream.toBytes();
      final duration = DateTime.now().difference(startTime);

      final headersMap = <String, String>{};
      request.headers.forEach((k, v) => headersMap[k] = v);

      final responseHeadersMap = <String, String>{};
      response.headers.forEach((k, v) => responseHeadersMap[k] = v);

      final call = AliceHttpCall(
        id: id,
        timestamp: startTime,
        method: request.method,
        uri: request.url.toString(),
        headers: headersMap,
        body: requestBody,
        statusCode: response.statusCode,
        responseHeaders: responseHeadersMap,
        responseBody: String.fromCharCodes(responseBytes),
        durationMs: duration.inMilliseconds,
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );

      alice.addCall(call);

      return http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      final call = AliceHttpCall(
        id: id,
        timestamp: startTime,
        method: request.method,
        uri: request.url.toString(),
        headers: request.headers,
        body: requestBody,
        durationMs: duration.inMilliseconds,
        isSuccess: false,
        error: e.toString(),
      );

      alice.addCall(call);
      rethrow;
    }
  }
}
