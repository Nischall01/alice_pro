import 'dart:async';
import 'dart:convert';
import 'package:alice_transport/alice_transport.dart';
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

  Alice({this.configuration = const AliceConfiguration()}) {
    _initWebSocket();
  }

  Stream<List<AliceHttpCall>> get callsStream => _callsStreamController.stream;
  List<AliceHttpCall> get calls => List.unmodifiable(_calls);

  void _initWebSocket() {
    final url = configuration.desktopCompanionUrl;
    if (url != null && url.isNotEmpty) {
      try {
        _wsChannel = WebSocketChannel.connect(Uri.parse(url));
      } catch (_) {}
    }
  }

  void addCall(AliceHttpCall rawCall) {
    // Attach device metadata if not already attached
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
      deviceId: rawCall.deviceId ?? configuration.deviceId ?? 'device_default',
      deviceName: rawCall.deviceName ?? configuration.deviceName ?? 'Mobile Device',
      deviceOs: rawCall.deviceOs ?? configuration.deviceOs ?? 'Mobile OS',
    );

    if (_calls.length >= configuration.maxCallsCount) {
      _calls.removeAt(0);
    }
    _calls.add(call);
    _callsStreamController.add(_calls);

    // Stream packet to desktop workstation
    if (_wsChannel != null) {
      try {
        _wsChannel!.sink.add(jsonEncode(call.toJson()));
      } catch (_) {}
    }
  }

  void clearCalls() {
    _calls.clear();
    _callsStreamController.add(_calls);
  }

  void dispose() {
    _callsStreamController.close();
    _wsChannel?.sink.close();
  }
}
