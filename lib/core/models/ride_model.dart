class RideLocation {
  final String address;
  final double lat;
  final double lng;

  const RideLocation({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory RideLocation.fromJson(Map<String, dynamic> json) => RideLocation(
    address: json['address'] ?? '',
    lat: (json['lat'] ?? 0).toDouble(),
    lng: (json['lng'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'address': address,
    'lat': lat,
    'lng': lng,
  };
}

class DriverInfo {
  final String id;
  final String name;
  final double rating;
  final String car;
  final String color;
  final String plate;
  final int eta;
  final String? photo;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.rating,
    required this.car,
    required this.color,
    required this.plate,
    required this.eta,
    this.photo,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) => DriverInfo(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? '',
    rating: (json['rating'] ?? 5.0).toDouble(),
    car: json['car'] ?? '',
    color: json['color'] ?? '',
    plate: json['plate'] ?? '',
    eta: json['eta'] ?? 5,
    photo: json['photo'],
  );
}

enum RideType { moto, basico, intermediario, vip }
enum RideStatus { idle, finding, driverComing, inProgress, rating, completed }

extension RideTypeExt on RideType {
  String get value {
    switch (this) {
      case RideType.moto: return 'moto';
      case RideType.basico: return 'basico';
      case RideType.intermediario: return 'intermediario';
      case RideType.vip: return 'vip';
    }
  }

  String get label {
    switch (this) {
      case RideType.moto: return 'ZeroFlash';
      case RideType.basico: return 'ZeroRisk';
      case RideType.intermediario: return 'ZeroPlus';
      case RideType.vip: return 'ZeroGold';
    }
  }

  String get description {
    switch (this) {
      case RideType.moto: return 'Rápido e econômico';
      case RideType.basico: return 'Conforto no dia a dia';
      case RideType.intermediario: return 'Mais espaço e conforto';
      case RideType.vip: return 'Experiência premium';
    }
  }

  double get pricePerKm {
    switch (this) {
      case RideType.moto: return 1.20;
      case RideType.basico: return 1.70;
      case RideType.intermediario: return 2.20;
      case RideType.vip: return 3.90;
    }
  }
}

class RideModel {
  final String id;
  final RideLocation origin;
  final RideLocation destination;
  final RideStatus status;
  final RideType rideType;
  final double price;
  final String distance;
  final String duration;
  final String createdAt;
  final DriverInfo? driver;
  final String? pin;
  final bool isEmergencyActive;

  const RideModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.status,
    required this.rideType,
    required this.price,
    required this.distance,
    required this.duration,
    required this.createdAt,
    this.driver,
    this.pin,
    this.isEmergencyActive = false,
  });

  RideModel copyWith({
    RideStatus? status,
    DriverInfo? driver,
    String? pin,
    bool? isEmergencyActive,
    double? price,
  }) => RideModel(
    id: id,
    origin: origin,
    destination: destination,
    status: status ?? this.status,
    rideType: rideType,
    price: price ?? this.price,
    distance: distance,
    duration: duration,
    createdAt: createdAt,
    driver: driver ?? this.driver,
    pin: pin ?? this.pin,
    isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
  );
}

class ChatMessage {
  final String msgId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;

  const ChatMessage({
    required this.msgId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    msgId: json['msgId'] ?? '',
    senderId: json['senderId'] ?? '',
    senderName: json['senderName'] ?? '',
    text: json['text'] ?? '',
    timestamp: json['timestamp'] ?? 0,
  );
}

double calculateFare(double distanceKm, RideType rideType, {bool isPeak = false}) {
  const double baseFee = 5.5;
  const double minFare = 10.0;
  final double surgeMultiplier = isPeak ? 1.5 : 1.0;
  final double raw = (baseFee + distanceKm * rideType.pricePerKm) * surgeMultiplier;
  return raw < minFare ? minFare : double.parse(raw.toStringAsFixed(2));
}

bool isCurrentlyPeakHour() {
  final hour = DateTime.now().hour;
  return (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
}
