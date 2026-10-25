import 'dart:async';
import 'package:alice_transport/alice_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AliceConfiguration {
  final String appName;
  final String? desktopCompanionUrl;
  final int maxCallsCount;

  const AliceConfiguration({
    this.appName = 'Alice App',
    this.desktopCompanionUrl,
    this.maxCallsCount = 1000,
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

  void addCall(AliceHttpCall call) {
    if (_calls.length >= configuration.maxCallsCount) {
      _calls.removeAt(0);
    }
    _calls.add(call);
    _callsStreamController.add(_calls);

    // Stream to desktop companion if connected
    if (_wsChannel != null) {
      try {
        _wsChannel!.sink.add(call.toJson().toString());
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
