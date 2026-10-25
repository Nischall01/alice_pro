import 'package:flutter_test/flutter_test.dart';
import 'package:alice_transport/alice_transport.dart';

void main() {
  group('AliceHttpCall JSON Serialization', () {
    test('AliceHttpCall round-trip JSON serialization', () {
      final now = DateTime.now();
      final originalCall = AliceHttpCall(
        id: 'call_123',
        timestamp: now,
        method: 'POST',
        uri: 'https://api.example.com/v1/users',
        headers: {'content-type': 'application/json'},
        body: '{"name":"Alice"}',
        statusCode: 201,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: '{"id":"usr_1","name":"Alice"}',
        durationMs: 145,
        isSuccess: true,
      );

      final jsonMap = originalCall.toJson();
      final deserializedCall = AliceHttpCall.fromJson(jsonMap);

      expect(deserializedCall.id, originalCall.id);
      expect(deserializedCall.method, originalCall.method);
      expect(deserializedCall.uri, originalCall.uri);
      expect(deserializedCall.headers, originalCall.headers);
      expect(deserializedCall.body, originalCall.body);
      expect(deserializedCall.statusCode, originalCall.statusCode);
      expect(deserializedCall.responseHeaders, originalCall.responseHeaders);
      expect(deserializedCall.responseBody, originalCall.responseBody);
      expect(deserializedCall.durationMs, originalCall.durationMs);
      expect(deserializedCall.isSuccess, originalCall.isSuccess);
    });
  });

  group('AliceDbTable & AliceDbQuery JSON Serialization', () {
    test('AliceDbTable round-trip serialization', () {
      const table = AliceDbTable(
        tableName: 'users',
        columns: ['id', 'name', 'email'],
        rowCount: 42,
      );

      final json = table.toJson();
      final result = AliceDbTable.fromJson(json);

      expect(result.tableName, table.tableName);
      expect(result.columns, table.columns);
      expect(result.rowCount, table.rowCount);
    });

    test('AliceDbQuery round-trip serialization', () {
      const query = AliceDbQuery(
        queryId: 'q_1',
        sql: 'SELECT * FROM users WHERE age > 21',
        columns: ['id', 'name', 'age'],
        rows: [
          [1, 'Alice', 25],
          [2, 'Bob', 30],
        ],
        executionTimeMs: 12,
      );

      final json = query.toJson();
      final result = AliceDbQuery.fromJson(json);

      expect(result.queryId, query.queryId);
      expect(result.sql, query.sql);
      expect(result.columns, query.columns);
      expect(result.rows.length, query.rows.length);
      expect(result.executionTimeMs, query.executionTimeMs);
    });
  });
}
