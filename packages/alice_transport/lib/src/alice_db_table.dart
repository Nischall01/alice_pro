import 'package:json_annotation/json_annotation.dart';

part 'alice_db_table.g.dart';

/// Database table schema packet
@JsonSerializable(explicitToJson: true)
class AliceDbTable {
  final String tableName;
  final List<String> columns;
  final int rowCount;

  const AliceDbTable({
    required this.tableName,
    required this.columns,
    required this.rowCount,
  });

  factory AliceDbTable.fromJson(Map<String, dynamic> json) =>
      _$AliceDbTableFromJson(json);

  Map<String, dynamic> toJson() => _$AliceDbTableToJson(this);
}
