import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

typedef SocketEventHandler = void Function(dynamic data);

class SocketService {
  io.Socket? _socket;
  final Map<String, List<SocketEventHandler>> _listeners = {};
  bool _connected = false;

  bool get isConnected => _connected;

  void connect(String token) {
    if (_socket != null && _connected) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.on('connect', (_) {
      _connected = true;
      _notifyListeners('connect', null);
    });

    _socket!.on('disconnect', (_) {
      _connected = false;
      _notifyListeners('disconnect', null);
    });

    _socket!.on('connect_error', (error) {
      _notifyListeners('connect_error', error);
    });

    _socket!.onAny((event, data) {
      _notifyListeners(event.toString(), data);
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _listeners.clear();
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _connected) {
      _socket!.emit(event, data);
    }
  }

  void on(String event, SocketEventHandler handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event, SocketEventHandler handler) {
    _listeners[event]?.remove(handler);
  }

  void offAll(String event) {
    _listeners.remove(event);
  }

  void _notifyListeners(String event, dynamic data) {
    for (final handler in List.of(_listeners[event] ?? [])) {
      handler(data);
    }
  }
}
