import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';

enum DriverStatus { offline, online, hasRequest, activeRide }

class IncomingRequest {
  final String rideId;
  final String passengerId;
  final String passengerName;
  final RideLocation origin;
  final RideLocation destination;
  final String rideType;
  final double price;
  final String distance;
  final String duration;
  final int receivedAt;

  const IncomingRequest({
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.rideType,
    required this.price,
    required this.distance,
    required this.duration,
    required this.receivedAt,
  });

  factory IncomingRequest.fromJson(Map<String, dynamic> json) => IncomingRequest(
    rideId: json['rideId']?.toString() ?? '',
    passengerId: json['passengerId']?.toString() ?? '',
    passengerName: json['passengerName'] ?? '',
    origin: RideLocation.fromJson(json['origin'] as Map<String, dynamic>),
    destination: RideLocation.fromJson(json['destination'] as Map<String, dynamic>),
    rideType: json['rideType'] ?? 'basico',
    price: (json['price'] ?? 15.0).toDouble(),
    distance: json['distance'] ?? '—',
    duration: json['duration'] ?? '—',
    receivedAt: json['receivedAt'] ?? DateTime.now().millisecondsSinceEpoch,
  );

  int get secondsRemaining {
    final elapsed = (DateTime.now().millisecondsSinceEpoch - receivedAt) ~/ 1000;
    return (30 - elapsed).clamp(0, 30);
  }
}

class DriverProvider extends ChangeNotifier {
  final SocketService _socket;
  final ApiService _api;

  DriverStatus _status = DriverStatus.offline;
  IncomingRequest? _incomingRequest;
  RideModel? _activeRide;
  LatLng? _myLocation;
  List<ChatMessage> _chatMessages = [];
  int _unreadCount = 0;
  Timer? _locationTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 30;
  StreamSubscription<Position>? _posStream;

  DriverStatus get status => _status;
  IncomingRequest? get incomingRequest => _incomingRequest;
  RideModel? get activeRide => _activeRide;
  LatLng? get myLocation => _myLocation;
  List<ChatMessage> get chatMessages => _chatMessages;
  int get unreadCount => _unreadCount;
  int get countdownSeconds => _countdownSeconds;

  DriverProvider({required SocketService socket, required ApiService api})
      : _socket = socket,
        _api = api {
    _initLocation();
    _bindSocketEvents();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _myLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {
      _myLocation = const LatLng(-22.9200, -42.5100);
    }
  }

  void _bindSocketEvents() {
    _socket.on('driver:new_request', (data) {
      if (data == null || _status == DriverStatus.offline) return;
      _incomingRequest = IncomingRequest.fromJson(data as Map<String, dynamic>);
      _status = DriverStatus.hasRequest;
      _countdownSeconds = 30;
      _startCountdown();
      notifyListeners();
    });

    _socket.on('driver:request_cancelled', (_) {
      _incomingRequest = null;
      _countdownTimer?.cancel();
      _status = DriverStatus.online;
      notifyListeners();
    });

    _socket.on('driver:trip_started', (data) {
      if (data == null) return;
      final d = data as Map<String, dynamic>;
      if (_incomingRequest != null) {
        _activeRide = RideModel(
          id: _incomingRequest!.rideId,
          origin: _incomingRequest!.origin,
          destination: _incomingRequest!.destination,
          status: RideStatus.inProgress,
          rideType: RideType.values.firstWhere(
            (t) => t.value == _incomingRequest!.rideType,
            orElse: () => RideType.basico,
          ),
          price: _incomingRequest!.price,
          distance: _incomingRequest!.distance,
          duration: _incomingRequest!.duration,
          createdAt: DateTime.now().toIso8601String(),
          pin: d['pin'] as String?,
        );
      }
      _incomingRequest = null;
      _status = DriverStatus.activeRide;
      _chatMessages = [];
      notifyListeners();
    });

    _socket.on('driver:trip_completed', (_) {
      _activeRide = null;
      _status = DriverStatus.online;
      _chatMessages = [];
      notifyListeners();
    });

    _socket.on('driver:ride_cancelled_by_passenger', (_) {
      _activeRide = null;
      _incomingRequest = null;
      _status = DriverStatus.online;
      notifyListeners();
    });

    _socket.on('chat:message', (data) {
      if (data == null) return;
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      _chatMessages = [..._chatMessages, msg];
      _unreadCount++;
      notifyListeners();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdownSeconds <= 0) {
        _countdownTimer?.cancel();
        if (_status == DriverStatus.hasRequest) {
          _rejectRequest();
        }
      } else {
        _countdownSeconds--;
        notifyListeners();
      }
    });
  }

  void goOnline(String driverId, String driverName) {
    _status = DriverStatus.online;
    notifyListeners();
    _socket.emit('driver:online', {
      'driverId': driverId,
      'driverName': driverName,
      'latitude': _myLocation?.latitude ?? -22.92,
      'longitude': _myLocation?.longitude ?? -42.51,
    });
    _startLocationStream(driverId);
  }

  void goOffline(String driverId) {
    _status = DriverStatus.offline;
    _incomingRequest = null;
    _countdownTimer?.cancel();
    notifyListeners();
    _socket.emit('driver:offline', {'driverId': driverId});
    _posStream?.cancel();
    _locationTimer?.cancel();
  }

  void acceptRequest() {
    if (_incomingRequest == null) return;
    _countdownTimer?.cancel();
    _socket.emit('driver:accept', {
      'rideId': _incomingRequest!.rideId,
      'passengerId': _incomingRequest!.passengerId,
      'driverLocation': {
        'latitude': _myLocation?.latitude,
        'longitude': _myLocation?.longitude,
      },
    });
    notifyListeners();
  }

  void _rejectRequest() {
    if (_incomingRequest == null) return;
    _socket.emit('driver:reject', {
      'rideId': _incomingRequest!.rideId,
    });
    _incomingRequest = null;
    _status = DriverStatus.online;
    notifyListeners();
  }

  void rejectRequest() => _rejectRequest();

  void startTrip() {
    if (_activeRide == null) return;
    _socket.emit('driver:start_trip', {'rideId': _activeRide!.id});
  }

  void completeTrip() {
    if (_activeRide == null) return;
    _socket.emit('driver:complete_trip', {'rideId': _activeRide!.id});
  }

  void sendChatMessage(String rideId, String senderId, String senderName, String text) {
    final msg = {
      'rideId': rideId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _socket.emit('chat:message', msg);
    final local = ChatMessage.fromJson(msg);
    _chatMessages = [..._chatMessages, local];
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void _startLocationStream(String driverId) {
    _posStream?.cancel();
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      _myLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
      if (_status != DriverStatus.offline) {
        _socket.emit('driver:location_update', {
          'driverId': driverId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        });
      }
    });
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _locationTimer?.cancel();
    _countdownTimer?.cancel();
    _socket.offAll('driver:new_request');
    _socket.offAll('driver:request_cancelled');
    _socket.offAll('driver:trip_started');
    _socket.offAll('driver:trip_completed');
    _socket.offAll('driver:ride_cancelled_by_passenger');
    _socket.offAll('chat:message');
    super.dispose();
  }
}
