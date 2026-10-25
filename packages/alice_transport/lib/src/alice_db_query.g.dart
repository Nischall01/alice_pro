// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alice_db_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliceDbQuery _$AliceDbQueryFromJson(Map<String, dynamic> json) => AliceDbQuery(
  queryId: json['queryId'] as String,
  sql: json['sql'] as String,
  columns:
      (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList() ??
      const [],
  executionTimeMs: (json['executionTimeMs'] as num).toInt(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$AliceDbQueryToJson(AliceDbQuery instance) =>
    <String, dynamic>{
      'queryId': instance.queryId,
      'sql': instance.sql,
      'columns': instance.columns,
      'rows': instance.rows,
      'executionTimeMs': instance.executionTimeMs,
      'error': instance.error,
    };
