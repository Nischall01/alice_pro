import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:alice_transport/alice_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AliceConfiguration {
  final String appName;
  final String? desktopCompanionUrl;
  final int maxCallsCount;
  final String? deviceId;
  final String? deviceName;
  final String? deviceOs;

  const AliceConfiguration({
    this.appName = 'Alice App',
    this.desktopCompanionUrl,
    this.maxCallsCount = 1000,
    this.deviceId,
    this.deviceName,
    this.deviceOs,
  });
}

class Alice {
  final AliceConfiguration configuration;
  final List<AliceHttpCall> _calls = [];
  final _callsStreamController = StreamController<List<AliceHttpCall>>.broadcast();

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  bool _isWsConnected = false;

  Alice({this.configuration = const AliceConfiguration()}) {
    _log('Initializing Alice Core (appName: "${configuration.appName}")');
    _initWebSocket();
  }

  Stream<List<AliceHttpCall>> get callsStream => _callsStreamController.stream;
  List<AliceHttpCall> get calls => List.unmodifiable(_calls);
  bool get isWebSocketConnected => _isWsConnected;

  void _log(String message) {
    dev.log('[Alice Core] $message');
    if (kDebugMode) {
      debugPrint('[Alice Core] $message');
    }
  }

  void _initWebSocket() {
    final url = configuration.desktopCompanionUrl;
    if (url == null || url.isEmpty) {
      _log('⚠️ desktopCompanionUrl is null or empty. WebSocket streaming disabled.');
      return;
    }

    _log('🔗 Connecting to Desktop Companion WebSocket URL: "$url"');
    _connectWebSocket(url);
  }

  void _connectWebSocket(String url) {
    try {
      final uri = Uri.parse(url);
      _wsChannel = WebSocketChannel.connect(uri);
      _log('Attempting connection to $url...');

      _wsSubscription?.cancel();
      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          _log('📩 Received message from server: $message');
        },
        onDone: () {
          _isWsConnected = false;
          _log('🔴 WebSocket connection closed by server ($url). Will attempt reconnect in 5s...');
          _scheduleReconnect(url);
        },
        onError: (error) {
          _isWsConnected = false;
          _log('❌ WebSocket error ($url): $error. Will attempt reconnect in 5s...');
          _scheduleReconnect(url);
        },
      );

      _isWsConnected = true;
      _log('✅ WebSocket channel connected successfully to $url');

      _sendHandshake();
    } catch (e, stack) {
      _isWsConnected = false;
      _log('❌ Failed to create WebSocket connection to $url: $e\n$stack');
      _scheduleReconnect(url);
    }
  }

  void _sendHandshake() {
    if (_wsChannel == null) return;
    try {
      final deviceId = configuration.deviceId ?? _defaultDeviceId;
      final deviceName = configuration.deviceName ?? _defaultDeviceName;
      final deviceOs = configuration.deviceOs ?? _defaultDeviceOs;

      final handshake = {
        'type': 'handshake',
        'appName': configuration.appName,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceOs': deviceOs,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _wsChannel!.sink.add(jsonEncode(handshake));
      _log('🤝 Handshake packet sent for device: "$deviceName" ($deviceId)');
    } catch (e) {
      _log('❌ Error sending handshake packet: $e');
    }
  }

  void _scheduleReconnect(String url) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _log('🔄 Retrying WebSocket connection to $url...');
      _connectWebSocket(url);
    });
  }

  String get _defaultDeviceId {
    if (kIsWeb) return 'web_browser';
    try {
      return '${Platform.operatingSystem}_${identityHashCode(this)}';
    } catch (_) {
      return 'device_unknown';
    }
  }

  String get _defaultDeviceName {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device/Emulator';
      if (Platform.isIOS) return 'iOS Device/Simulator';
      if (Platform.isWindows) return 'Windows App';
      if (Platform.isMacOS) return 'macOS App';
      if (Platform.isLinux) return 'Linux App';
      return Platform.operatingSystem;
    } catch (_) {
      return 'Mobile Device';
    }
  }

  String get _defaultDeviceOs {
    if (kIsWeb) return 'Web';
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'Mobile OS';
    }
  }

  void addCall(AliceHttpCall rawCall) {
    final call = AliceHttpCall(
      id: rawCall.id,
      timestamp: rawCall.timestamp,
      method: rawCall.method,
      uri: rawCall.uri,
      headers: rawCall.headers,
      body: rawCall.body,
      statusCode: rawCall.statusCode,
      responseHeaders: rawCall.responseHeaders,
      responseBody: rawCall.responseBody,
      durationMs: rawCall.durationMs,
      isSuccess: rawCall.isSuccess,
      error: rawCall.error,
      deviceId: rawCall.deviceId ?? configuration.deviceId ?? _defaultDeviceId,
      deviceName: rawCall.deviceName ?? configuration.deviceName ?? _defaultDeviceName,
      deviceOs: rawCall.deviceOs ?? configuration.deviceOs ?? _defaultDeviceOs,
    );

    _log('📡 Intercepted Call: [${call.method}] ${call.uri} -> Status: ${call.statusCode ?? 'ERR'}');

    if (_calls.length >= configuration.maxCallsCount) {
      _calls.removeAt(0);
    }
    _calls.add(call);
    _callsStreamController.add(_calls);

    // Stream packet to desktop workstation
    final companionUrl = configuration.desktopCompanionUrl;
    if (companionUrl != null && companionUrl.isNotEmpty) {
      if (_wsChannel != null) {
        try {
          final payload = jsonEncode(call.toJson());
          _wsChannel!.sink.add(payload);
          _log('🚀 Sent HTTP Call packet (${call.id}) to desktop companion ($companionUrl)');
        } catch (e, stack) {
          _log('❌ Exception sending packet over WebSocket: $e\n$stack');
        }
      } else {
        _log('⚠️ Cannot send call packet: WebSocket channel is null ($companionUrl)');
      }
    } else {
      _log('ℹ️ Remote desktop streaming skipped (desktopCompanionUrl is null/empty)');
    }
  }

  void clearCalls() {
    _calls.clear();
    _callsStreamController.add(_calls);
    _log('🧹 Cleared all captured HTTP calls.');
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _wsSubscription?.cancel();
    _callsStreamController.close();
    _wsChannel?.sink.close();
    _log('Disposed Alice Core.');
  }
}
