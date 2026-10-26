// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alice_http_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliceHttpCall _$AliceHttpCallFromJson(Map<String, dynamic> json) =>
    AliceHttpCall(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      method: json['method'] as String,
      uri: json['uri'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      body: json['body'] as String?,
      statusCode: (json['statusCode'] as num?)?.toInt(),
      responseHeaders: (json['responseHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      responseBody: json['responseBody'] as String?,
      durationMs: (json['durationMs'] as num).toInt(),
      isSuccess: json['isSuccess'] as bool? ?? true,
      error: json['error'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceOs: json['deviceOs'] as String?,
    );

Map<String, dynamic> _$AliceHttpCallToJson(AliceHttpCall instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'method': instance.method,
      'uri': instance.uri,
      'headers': instance.headers,
      'body': instance.body,
      'statusCode': instance.statusCode,
      'responseHeaders': instance.responseHeaders,
      'responseBody': instance.responseBody,
      'durationMs': instance.durationMs,
      'isSuccess': instance.isSuccess,
      'error': instance.error,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceOs': instance.deviceOs,
    };
