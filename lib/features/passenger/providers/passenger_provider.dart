import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';

enum PassengerPhase {
  idle,
  typing,
  confirming,
  finding,
  driverComing,
  inProgress,
  rating,
}

class PassengerProvider extends ChangeNotifier {
  final SocketService _socket;
  final ApiService _api;

  PassengerPhase _phase = PassengerPhase.idle;
  RideModel? _currentRide;
  LatLng? _userLocation;
  LatLng? _driverLocation;
  List<LatLng> _routeCoords = [];
  List<ChatMessage> _chatMessages = [];
  int _unreadCount = 0;
  RideType _selectedRideType = RideType.basico;

  PassengerPhase get phase => _phase;
  RideModel? get currentRide => _currentRide;
  LatLng? get userLocation => _userLocation;
  LatLng? get driverLocation => _driverLocation;
  List<LatLng> get routeCoords => _routeCoords;
  List<ChatMessage> get chatMessages => _chatMessages;
  int get unreadCount => _unreadCount;
  RideType get selectedRideType => _selectedRideType;

  PassengerProvider({required SocketService socket, required ApiService api})
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _userLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {
      _userLocation = const LatLng(-22.9200, -42.5100);
      notifyListeners();
    }
  }

  void _bindSocketEvents() {
    _socket.on('passenger:driver_found', (data) {
      if (data == null) return;
      final d = data as Map<String, dynamic>;
      final driver = DriverInfo.fromJson(d['driver'] as Map<String, dynamic>);
      _currentRide = _currentRide?.copyWith(status: RideStatus.driverComing, driver: driver);
      _phase = PassengerPhase.driverComing;
      notifyListeners();
    });

    _socket.on('passenger:trip_started', (_) {
      _currentRide = _currentRide?.copyWith(status: RideStatus.inProgress);
      _phase = PassengerPhase.inProgress;
      notifyListeners();
    });

    _socket.on('passenger:trip_completed', (_) {
      _currentRide = _currentRide?.copyWith(status: RideStatus.completed);
      _phase = PassengerPhase.rating;
      notifyListeners();
    });

    _socket.on('passenger:no_drivers', (_) {
      _phase = PassengerPhase.idle;
      _currentRide = null;
      _routeCoords = [];
      notifyListeners();
    });

    _socket.on('passenger:price_confirmed', (data) {
      if (data == null || _currentRide == null) return;
      final d = data as Map<String, dynamic>;
      _currentRide = _currentRide!.copyWith(
        pin: d['pin'] as String?,
        price: (d['price'] as num?)?.toDouble(),
      );
      notifyListeners();
    });

    _socket.on('passenger:ride_cancelled_by_driver', (_) {
      _phase = PassengerPhase.idle;
      _currentRide = null;
      _routeCoords = [];
      _driverLocation = null;
      notifyListeners();
    });

    _socket.on('passenger:error', (_) {
      _phase = PassengerPhase.idle;
      _currentRide = null;
      _routeCoords = [];
      notifyListeners();
    });

    _socket.on('driver:location_update', (data) {
      if (data == null) return;
      final d = data as Map<String, dynamic>;
      _driverLocation = LatLng(
        (d['latitude'] as num).toDouble(),
        (d['longitude'] as num).toDouble(),
      );
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

  void selectRideType(RideType type) {
    _selectedRideType = type;
    notifyListeners();
  }

  void setPhase(PassengerPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  void setPreviewRide(RideModel ride) {
    _currentRide = ride;
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void sendChatMessage(String rideId, String senderId, String senderName, String text) {
    final msg = {
      'msgId': const Uuid().v4(),
      'rideId': rideId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _socket.emit('chat:message', msg);
    _chatMessages = [..._chatMessages, ChatMessage.fromJson(msg)];
    notifyListeners();
  }

  void requestRide({
    required RideLocation origin,
    required RideLocation destination,
    required String passengerId,
    required String passengerName,
    required double distanceKm,
  }) {
    final price = calculatePrice(distanceKm);
    final rideId =
        '${DateTime.now().millisecondsSinceEpoch}${const Uuid().v4().substring(0, 5)}';

    _currentRide = RideModel(
      id: rideId,
      origin: origin,
      destination: destination,
      status: RideStatus.finding,
      rideType: _selectedRideType,
      price: price,
      distance: '${distanceKm.toStringAsFixed(1)} km',
      duration: '${(distanceKm * 2.5).round()} min',
      createdAt: DateTime.now().toIso8601String(),
    );

    _phase = PassengerPhase.finding;
    _chatMessages = [];
    _unreadCount = 0;
    notifyListeners();

    _socket.emit('passenger:request_ride', {
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'rideType': _selectedRideType.value,
      'price': price,
      'distanceKm': distanceKm,
      'distance': '${distanceKm.toStringAsFixed(1)} km',
      'duration': '${(distanceKm * 2.5).round()} min',
    });

    Timer(const Duration(seconds: 70), () {
      if (_phase == PassengerPhase.finding) cancelRide();
    });
  }

  void cancelRide() {
    if (_currentRide != null) {
      _socket.emit('passenger:cancel', {'rideId': _currentRide!.id});
    }
    _phase = PassengerPhase.idle;
    _currentRide = null;
    _routeCoords = [];
    _driverLocation = null;
    _chatMessages = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> rateDriver(int stars) async {
    if (_currentRide?.driver != null && stars > 0) {
      try {
        await _api.submitRating(
          rideId: _currentRide!.id,
          ratedId: int.tryParse(_currentRide!.driver!.id) ?? 0,
          stars: stars,
          role: 'passenger',
        );
      } catch (_) {}
    }
    _phase = PassengerPhase.idle;
    _currentRide = null;
    _routeCoords = [];
    _driverLocation = null;
    _chatMessages = [];
    _unreadCount = 0;
    notifyListeners();
  }

  void triggerSOS() {
    if (_currentRide == null) return;
    _socket.emit('ride:emergency', {'rideId': _currentRide!.id});
    _currentRide = _currentRide!.copyWith(isEmergencyActive: true);
    notifyListeners();
  }

  double calculatePrice(double distanceKm) =>
      calculateFare(distanceKm, _selectedRideType, isPeak: isCurrentlyPeakHour());

  @override
  void dispose() {
    _socket.offAll('passenger:driver_found');
    _socket.offAll('passenger:trip_started');
    _socket.offAll('passenger:trip_completed');
    _socket.offAll('passenger:no_drivers');
    _socket.offAll('passenger:price_confirmed');
    _socket.offAll('passenger:ride_cancelled_by_driver');
    _socket.offAll('passenger:error');
    _socket.offAll('driver:location_update');
    _socket.offAll('chat:message');
    super.dispose();
  }
}
