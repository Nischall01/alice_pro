import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf_io.dart' as init_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:alice_transport/alice_transport.dart';

class AliceWebSocketServer {
  final int port;
  final _callStreamController = StreamController<AliceHttpCall>.broadcast();

  AliceWebSocketServer({this.port = 4040});

  Stream<AliceHttpCall> get onCallReceived => _callStreamController.stream;

  Future<void> start() async {
    final handler = webSocketHandler((webSocket, [protocol]) {
      webSocket.stream.listen((message) {
        try {
          final Map<String, dynamic> json = jsonDecode(message.toString());
          final call = AliceHttpCall.fromJson(json);
          _callStreamController.add(call);
        } catch (_) {}
      });
    });

    try {
      await init_io.serve(handler, '0.0.0.0', port);
    } catch (_) {}
  }

  void stop() {
    _callStreamController.close();
  }
}
