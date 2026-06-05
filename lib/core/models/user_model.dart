class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isApproved;
  final bool suspended;
  final String? profilePhotoUrl;
  final double driverRating;
  final double passengerRating;
  final int totalRides;
  final String rgStatus;
  final String cnhStatus;
  final String crlvStatus;
  final String? vehiclePlate;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleType;
  final String? vehicleColor;
  final bool subscriptionActive;
  final String? subscriptionExpiresAt;
  final double cancellationFeeOwed;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isApproved = false,
    this.suspended = false,
    this.profilePhotoUrl,
    this.driverRating = 5.0,
    this.passengerRating = 5.0,
    this.totalRides = 0,
    this.rgStatus = 'pending',
    this.cnhStatus = 'pending',
    this.crlvStatus = 'pending',
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleType,
    this.vehicleColor,
    this.subscriptionActive = false,
    this.subscriptionExpiresAt,
    this.cancellationFeeOwed = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'passenger',
      isApproved: json['isApproved'] ?? false,
      suspended: json['suspended'] ?? false,
      profilePhotoUrl: json['profilePhotoUrl'],
      driverRating: (json['driverRating'] ?? 5.0).toDouble(),
      passengerRating: (json['passengerRating'] ?? 5.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      rgStatus: json['rgStatus'] ?? 'pending',
      cnhStatus: json['cnhStatus'] ?? 'pending',
      crlvStatus: json['crlvStatus'] ?? 'pending',
      vehiclePlate: json['vehiclePlate'],
      vehicleModel: json['vehicleModel'],
      vehicleYear: json['vehicleYear'],
      vehicleType: json['vehicleType'],
      vehicleColor: json['vehicleColor'],
      subscriptionActive: json['subscriptionActive'] ?? false,
      subscriptionExpiresAt: json['subscriptionExpiresAt'],
      cancellationFeeOwed: (json['cancellationFeeOwed'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'isApproved': isApproved,
    'suspended': suspended,
    'profilePhotoUrl': profilePhotoUrl,
    'driverRating': driverRating,
    'passengerRating': passengerRating,
    'totalRides': totalRides,
    'rgStatus': rgStatus,
    'cnhStatus': cnhStatus,
    'crlvStatus': crlvStatus,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehicleType': vehicleType,
    'vehicleColor': vehicleColor,
    'subscriptionActive': subscriptionActive,
    'subscriptionExpiresAt': subscriptionExpiresAt,
    'cancellationFeeOwed': cancellationFeeOwed,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? profilePhotoUrl,
    bool? isApproved,
    bool? suspended,
    double? driverRating,
    double? passengerRating,
    int? totalRides,
    String? rgStatus,
    String? cnhStatus,
    String? crlvStatus,
    String? vehiclePlate,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleType,
    String? vehicleColor,
    bool? subscriptionActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      isApproved: isApproved ?? this.isApproved,
      suspended: suspended ?? this.suspended,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      driverRating: driverRating ?? this.driverRating,
      passengerRating: passengerRating ?? this.passengerRating,
      totalRides: totalRides ?? this.totalRides,
      rgStatus: rgStatus ?? this.rgStatus,
      cnhStatus: cnhStatus ?? this.cnhStatus,
      crlvStatus: crlvStatus ?? this.crlvStatus,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      cancellationFeeOwed: cancellationFeeOwed,
    );
  }
}
