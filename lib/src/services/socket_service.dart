import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  // ==============================
  // CONNECT
  // ==============================
  void connect({
    required String userId,

    /// HOME PAGE
    void Function(Map<String, dynamic> data)? onRoomCreated,
    VoidCallback? onRoomVanished,
    void Function(Map<String, dynamic> data)? onRoomStatus, // NEW

    /// CALL SCREEN
    void Function(Map<String, dynamic> data)? onJoined,
    void Function(Map<String, dynamic> data)? onSpeaking,
    void Function(Map<String, dynamic> data)? onListening,
    void Function(Map<String, dynamic> data)? onUserLeft,

    /// LIFECYCLE
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
    void Function(dynamic error)? onError,
  }) {
    // Force creation of a new socket instance
    _socket?.dispose();
    _socket = null;
    if (_socket != null && _socket!.connected) {
      debugPrint('⚠️ Socket already connected');
      return;
    }

    _socket = IO.io(
      'https://voizer.live',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': userId})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🟢 Socket connected | id: ${_socket!.id}');
      onConnected?.call();

      // Ask backend for current room state
      // _socket!.emit('checkRoomRunning');
    });

    // Listen for backend response to checkRoomRunning
    _socket!.on('roomRunning', (data) {
      debugPrint('📡 roomRunning: $data');
      onRoomStatus?.call(Map<String, dynamic>.from(data));
    });

    // Existing event listeners
    _socket!.on('roomCreated',
        (data) => onRoomCreated?.call(Map<String, dynamic>.from(data)));
    _socket!.on('RoomVanished', (_) => onRoomVanished?.call());
    _socket!.on(
        'joined', (data) => onJoined?.call(Map<String, dynamic>.from(data)));
    _socket!.on('speaking',
        (data) => onSpeaking?.call(Map<String, dynamic>.from(data)));
    _socket!.on('listening',
        (data) => onListening?.call(Map<String, dynamic>.from(data)));
    _socket!.on('userLeft',
        (data) => onUserLeft?.call(Map<String, dynamic>.from(data)));
    _socket!.onError((error) => onError?.call(error));
  }

  void checkRoomRunning() {
    if (!isConnected) return;
    debugPrint('📡 Emitting checkRoomRunning');
    _socket!.emit('roomRunning');
  }
  // ==============================
  // EMIT EVENTS
  // ==============================

  /// Join room (CALL SCREEN)
  void joinRoom() {
    if (!isConnected) return;
    _socket!.emit('joinRoom');
  }

  /// Mic ON
  void speak() {
    if (!isConnected) return;
    _socket!.emit('speak');
  }

  /// Mic OFF
  void listen() {
    if (!isConnected) return;
    _socket!.emit('listen');
  }

  /// Leave room
  void leaveRoom() {
    if (!isConnected) return;
    _socket!.emit('left');
  }

  // ==============================
  // DISCONNECT
  // ==============================
  void disconnect() {
    if (_socket == null) return;

    debugPrint('🔥 Destroying socket completely');

    try {
      // ❌ Do NOT emit anything here (no leaveRoom)
      _socket!.clearListeners(); // ✅ removes ALL listeners
      _socket!.disconnect(); // ✅ force disconnect
      _socket!.dispose(); // ✅ free native resources
    } catch (e) {
      debugPrint('Socket dispose error: $e');
    } finally {
      _socket = null;
    }

    debugPrint('🧹 Socket fully disposed');
  }
}
