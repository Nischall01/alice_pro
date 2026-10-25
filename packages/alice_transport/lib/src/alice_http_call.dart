import 'package:json_annotation/json_annotation.dart';

part 'alice_http_call.g.dart';

/// Network request and response packet for transport layer
@JsonSerializable(explicitToJson: true)
class AliceHttpCall {
  final String id;
  final DateTime timestamp;
  final String method;
  final String uri;
  final Map<String, String> headers;
  final String? body;
  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final int durationMs;
  final bool isSuccess;
  final String? error;

  const AliceHttpCall({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    required this.durationMs,
    this.isSuccess = true,
    this.error,
  });

  factory AliceHttpCall.fromJson(Map<String, dynamic> json) =>
      _$AliceHttpCallFromJson(json);

  Map<String, dynamic> toJson() => _$AliceHttpCallToJson(this);
}
