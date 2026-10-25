import 'package:json_annotation/json_annotation.dart';

part 'alice_db_query.g.dart';

/// Database query and result payload
@JsonSerializable(explicitToJson: true)
class AliceDbQuery {
  final String queryId;
  final String sql;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final int executionTimeMs;
  final String? error;

  const AliceDbQuery({
    required this.queryId,
    required this.sql,
    this.columns = const [],
    this.rows = const [],
    required this.executionTimeMs,
    this.error,
  });

  factory AliceDbQuery.fromJson(Map<String, dynamic> json) =>
      _$AliceDbQueryFromJson(json);

  Map<String, dynamic> toJson() => _$AliceDbQueryToJson(this);
}
