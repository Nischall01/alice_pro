import 'package:alice_transport/alice_transport.dart';

/// Mock data for the network inspector prototype
class MockData {
  static List<AliceHttpCall> generateSampleCalls() {
    final now = DateTime.now();
    return [
      AliceHttpCall(
        id: 'call_001',
        timestamp: now.subtract(const Duration(minutes: 2)),
        method: 'GET',
        uri: 'https://api.github.com/repos/flutter/flutter',
        headers: const {'Authorization': 'Bearer ****', 'Accept': 'application/json'},
        body: null,
        statusCode: 200,
        responseHeaders: const {'content-type': 'application/json; charset=utf-8'},
        responseBody: '{"name":"flutter","full_name":"flutter/flutter","stargazers_count":156789}',
        durationMs: 342,
      ),
      AliceHttpCall(
        id: 'call_002',
        timestamp: now.subtract(const Duration(minutes: 1, seconds: 45)),
        method: 'POST',
        uri: 'https://auth.example.com/api/v1/login',
        headers: const {'Content-Type': 'application/json', 'X-App-Version': '1.0.0'},
        body: '{"email":"user@example.com","password":"****"}',
        statusCode: 200,
        responseHeaders: const {'content-type': 'application/json', 'set-cookie': 'session=****'},
        responseBody: '{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.****","expires_in":3600}',
        durationMs: 891,
      ),
      AliceHttpCall(
        id: 'call_003',
        timestamp: now.subtract(const Duration(minutes: 1, seconds: 30)),
        method: 'GET',
        uri: 'https://api.example.com/v1/users/me/profile',
        headers: const {'Authorization': 'Bearer eyJhbG****', 'Accept': 'application/json'},
        body: null,
        statusCode: 200,
        responseHeaders: const {'content-type': 'application/json'},
        responseBody: '{"id":"usr_123","name":"Alice Developer","email":"alice@example.com"}',
        durationMs: 156,
      ),
      AliceHttpCall(
        id: 'call_004',
        timestamp: now.subtract(const Duration(minutes: 1, seconds: 15)),
        method: 'PUT',
        uri: 'https://api.example.com/v1/users/me/profile',
        headers: const {'Authorization': 'Bearer eyJhbG****', 'Content-Type': 'application/json'},
        body: '{"name":"Alice Dev","bio":"Building awesome things"}',
        statusCode: 200,
        responseHeaders: const {'content-type': 'application/json'},
        responseBody: '{"id":"usr_123","name":"Alice Dev","bio":"Building awesome things"}',
        durationMs: 234,
      ),
      AliceHttpCall(
        id: 'call_005',
        timestamp: now.subtract(const Duration(minutes: 1)),
        method: 'GET',
        uri: 'https://cdn.example.com/images/hero-banner.webp',
        headers: const {'Accept': 'image/webp,image/png,*/*'},
        body: null,
        statusCode: 200,
        responseHeaders: const {'content-type': 'image/webp', 'cache-control': 'public, max-age=86400'},
        responseBody: '[Binary data - 245KB]',
        durationMs: 89,
      ),
    ];
  }
}
