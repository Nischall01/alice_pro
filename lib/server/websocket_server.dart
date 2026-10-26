import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf_io.dart' as init_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:alice_transport/alice_transport.dart';

class AliceWebSocketServer {
  final int port;
  final _callStreamController = StreamController<AliceHttpCall>.broadcast();
  final _deviceConnectedController = StreamController<AliceDeviceInfo>.broadcast();
  int _activeConnectionsCount = 0;

  AliceWebSocketServer({this.port = 4040});

  Stream<AliceHttpCall> get onCallReceived => _callStreamController.stream;
  Stream<AliceDeviceInfo> get onDeviceConnected => _deviceConnectedController.stream;
  int get activeConnectionsCount => _activeConnectionsCount;

  void _log(String message) {
    dev.log('[Alice WS Server] $message');
    if (kDebugMode) {
      debugPrint('[Alice WS Server] $message');
    }
  }

  Future<void> start() async {
    final handler = webSocketHandler((webSocket, [protocol]) {
      _activeConnectionsCount++;
      _log('🟢 New client connected! Total active connections: $_activeConnectionsCount');

      webSocket.stream.listen((message) {
        _log('📩 Received payload: ${message.toString()}');
        try {
          final Map<String, dynamic> json = jsonDecode(message.toString());
          if (json.containsKey('type') && json['type'] == 'handshake') {
            final appName = json['appName'] ?? 'App';
            final deviceName = json['deviceName'] ?? 'Device';
            final deviceOs = json['deviceOs'] ?? 'Mobile';
            final deviceId = json['deviceId'] ?? 'device';

            _log('🤝 Handshake registered: App="$appName", Device="$deviceName" ($deviceId), OS="$deviceOs"');
            final info = AliceDeviceInfo(
              appName: appName,
              deviceName: deviceName,
              platform: deviceOs,
              osVersion: deviceOs,
            );
            _deviceConnectedController.add(info);
          } else {
            final call = AliceHttpCall.fromJson(json);
            _log('📥 Captured HTTP Call: ${call.method} ${call.uri} [Status: ${call.statusCode ?? 'ERR'}] from device "${call.deviceName}" (${call.deviceId})');
            _callStreamController.add(call);
          }
        } catch (e, stack) {
          _log('❌ Error parsing payload: $e\n$stack');
        }
      }, onDone: () {
        if (_activeConnectionsCount > 0) _activeConnectionsCount--;
        _log('🔴 Client disconnected. Active connections remaining: $_activeConnectionsCount');
      }, onError: (err) {
        if (_activeConnectionsCount > 0) _activeConnectionsCount--;
        _log('❌ Client socket error: $err. Active connections remaining: $_activeConnectionsCount');
      });
    });

    try {
      final server = await init_io.serve(handler, '0.0.0.0', port);
      _log('🚀 Server listening on ws://${server.address.host}:${server.port}/ (all interfaces)');
    } catch (e, stack) {
      _log('❌ Failed to start server on port $port: $e\n$stack');
    }
  }

  void stop() {
    _callStreamController.close();
    _deviceConnectedController.close();
    _log('Server stopped.');
  }
}
