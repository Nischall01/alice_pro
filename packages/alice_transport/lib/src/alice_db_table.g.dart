// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alice_db_table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliceDbTable _$AliceDbTableFromJson(Map<String, dynamic> json) => AliceDbTable(
  tableName: json['tableName'] as String,
  columns: (json['columns'] as List<dynamic>).map((e) => e as String).toList(),
  rowCount: (json['rowCount'] as num).toInt(),
);

Map<String, dynamic> _$AliceDbTableToJson(AliceDbTable instance) =>
    <String, dynamic>{
      'tableName': instance.tableName,
      'columns': instance.columns,
      'rowCount': instance.rowCount,
    };
