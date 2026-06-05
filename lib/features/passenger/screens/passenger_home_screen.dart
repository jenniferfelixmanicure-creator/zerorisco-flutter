import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/shared/widgets/app_map_widget.dart';
import '../../../features/shared/widgets/sos_button.dart';
import '../../../features/shared/widgets/ride_chat_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/passenger_provider.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  bool _showChat = false;
  int _ratingStars = 5;

  @override
  Widget build(BuildContext context) {
    final passenger = context.watch<PassengerProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AppMapWidget(
            origin: passenger.userLocation,
            destination: passenger.currentRide != null
                ? LatLng(
                    passenger.currentRide!.destination.lat,
                    passenger.currentRide!.destination.lng,
                  )
                : null,
            driverLocation: passenger.driverLocation,
            routeCoords: passenger.routeCoords,
          ),

          _buildTopBar(context, auth),

          if (passenger.phase == PassengerPhase.driverComing ||
              passenger.phase == PassengerPhase.inProgress)
            SosButton(onActivated: passenger.triggerSOS),

          if (_showChat && passenger.currentRide != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showChat = false),
                child: Container(color: Colors.black54),
              ),
            ),

          if (_showChat && passenger.currentRide != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: RideChatWidget(
                myId: auth.user?.id ?? '',
                myName: auth.user?.name ?? '',
                otherName: passenger.currentRide?.driver?.name ?? 'Motorista',
                messages: passenger.chatMessages,
                onSend: (text) => passenger.sendChatMessage(
                  passenger.currentRide!.id,
                  auth.user?.id ?? '',
                  auth.user?.name ?? '',
                  text,
                ),
                onClose: () => setState(() => _showChat = false),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomPanel(context, passenger, auth),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider auth) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _topBtn(Icons.person_rounded, () {}),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: Text(
                  'ZeroRisco',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              _topBtn(Icons.history_rounded, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    PassengerProvider passenger,
    AuthProvider auth,
  ) {
    return switch (passenger.phase) {
      PassengerPhase.idle || PassengerPhase.typing => _buildIdlePanel(context, passenger),
      PassengerPhase.confirming => _buildConfirmingPanel(context, passenger, auth),
      PassengerPhase.finding => _buildFindingPanel(passenger),
      PassengerPhase.driverComing => _buildDriverComingPanel(context, passenger),
      PassengerPhase.inProgress => _buildInProgressPanel(passenger),
      PassengerPhase.rating => _buildRatingPanel(passenger),
    };
  }

  Widget _buildIdlePanel(BuildContext context, PassengerProvider passenger) {
    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 16),
      Text(
        'Para onde você vai?',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => _openDestinationPicker(context, passenger),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text('Buscar destino...', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Divider(color: AppColors.border),
      const SizedBox(height: 12),
      Row(
        children: [
          _quickDest(Icons.home_rounded, 'Casa'),
          const SizedBox(width: 10),
          _quickDest(Icons.work_rounded, 'Trabalho'),
          const SizedBox(width: 10),
          _quickDest(Icons.favorite_rounded, 'Favoritos'),
        ],
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildConfirmingPanel(
    BuildContext context,
    PassengerProvider passenger,
    AuthProvider auth,
  ) {
    final ride = passenger.currentRide;
    if (ride == null) return const SizedBox.shrink();
    final distanceKm = double.tryParse(
          ride.distance.replaceAll(' km', '').replaceAll(',', '.'),
        ) ??
        5.0;

    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 14),
      const Text(
        'Escolha o tipo de corrida',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      ...RideType.values.map((type) {
        final selected = passenger.selectedRideType == type;
        final price = calculateFare(distanceKm, type, isPeak: isCurrentlyPeakHour());
        return _RideTypeCard(
          type: type,
          price: price,
          isSelected: selected,
          onTap: () => passenger.selectRideType(type),
        );
      }),
      const SizedBox(height: 18),
      ElevatedButton(
        onPressed: () => passenger.requestRide(
          origin: ride.origin,
          destination: ride.destination,
          passengerId: auth.user?.id ?? '',
          passengerName: auth.user?.name ?? '',
          distanceKm: distanceKm,
        ),
        child: Text(
          'Confirmar — R\$ ${passenger.calculatePrice(distanceKm).toStringAsFixed(2)}',
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => passenger.setPhase(PassengerPhase.idle),
        child: const Text('Cancelar'),
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildFindingPanel(PassengerProvider passenger) {
    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 24),
      Center(
        child: Column(
          children: [
            _PulseRing(),
            const SizedBox(height: 20),
            const Text(
              'Procurando motorista...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando ao motorista mais próximo de você',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: passenger.cancelRide,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          foregroundColor: AppColors.error,
        ),
        child: const Text('Cancelar corrida'),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildDriverComingPanel(BuildContext context, PassengerProvider passenger) {
    final driver = passenger.currentRide?.driver;
    if (driver == null) return const SizedBox.shrink();

    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 14),
      Row(
        children: [
          _driverAvatar(driver.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(driver.rating.toStringAsFixed(1),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('·', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('${driver.car} ${driver.color}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _plateBadge(driver.plate),
              const SizedBox(height: 4),
              Text(
                '${driver.eta} min',
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (passenger.currentRide?.pin != null) ...[
        _PinCard(pin: passenger.currentRide!.pin!),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                passenger.clearUnread();
                setState(() => _showChat = true);
              },
              icon: _chatIcon(passenger.unreadCount),
              label: const Text('Chat'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: passenger.cancelRide,
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
              label: const Text('Cancelar', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildInProgressPanel(PassengerProvider passenger) {
    final ride = passenger.currentRide;
    if (ride == null) return const SizedBox.shrink();

    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 12),
      Row(
        children: [
          Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
          const SizedBox(width: 8),
          Text('Corrida em andamento',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 12),
      _routeCard(ride.origin.address, ride.destination.address),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () {
          passenger.clearUnread();
          setState(() => _showChat = true);
        },
        icon: _chatIcon(passenger.unreadCount),
        label: const Text('Abrir chat'),
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildRatingPanel(PassengerProvider passenger) {
    final driver = passenger.currentRide?.driver;
    return _Sheet(children: [
      _handle(),
      const SizedBox(height: 16),
      const Center(
        child: Text('Corrida concluída! 🎉',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Como foi com ${driver?.name ?? 'o motorista'}?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
      const SizedBox(height: 22),
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _ratingStars = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _ratingStars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: () => passenger.rateDriver(_ratingStars),
        child: const Text('Avaliar motorista'),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => passenger.rateDriver(0),
        child: Text('Pular avaliação', style: TextStyle(color: AppColors.textMuted)),
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration:
              BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _quickDest(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _driverAvatar(String name) {
    final initials = name.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
    );
  }

  Widget _plateBadge(String plate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        plate.toUpperCase(),
        style: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _chatIcon(int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_rounded, size: 18),
        if (unread > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              child: Text('$unread',
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _routeCard(String origin, String destination) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _routeRow(Icons.circle, AppColors.primary, origin),
          const SizedBox(height: 8),
          _routeRow(Icons.location_pin, AppColors.error, destination),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _openDestinationPicker(BuildContext context, PassengerProvider passenger) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationSheet(
        onSelected: (dest) {
          Navigator.of(context).pop();
          final origin = RideLocation(
            address: 'Localização atual',
            lat: passenger.userLocation?.latitude ?? -22.92,
            lng: passenger.userLocation?.longitude ?? -42.51,
          );
          final distKm = const Distance().as(
            LengthUnit.Kilometer,
            LatLng(origin.lat, origin.lng),
            LatLng(dest.lat, dest.lng),
          ).clamp(1.0, 200.0);

          passenger.setPreviewRide(RideModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            origin: origin,
            destination: dest,
            status: RideStatus.idle,
            rideType: passenger.selectedRideType,
            price: passenger.calculatePrice(distKm),
            distance: '${distKm.toStringAsFixed(1)} km',
            duration: '${(distKm * 2.5).round()} min',
            createdAt: DateTime.now().toIso8601String(),
          ));
          passenger.setPhase(PassengerPhase.confirming);
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final List<Widget> children;
  const _Sheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _RideTypeCard extends StatelessWidget {
  final RideType type;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const _RideTypeCard({
    required this.type,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon => switch (type) {
    RideType.moto => Icons.two_wheeler_rounded,
    RideType.basico => Icons.directions_car_rounded,
    RideType.intermediario => Icons.directions_car_filled_rounded,
    RideType.vip => Icons.star_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isSelected ? AppColors.primary : AppColors.textMuted).withValues(alpha: 0.12),
              ),
              child: Icon(
                _icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text(type.description,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              'R\$ ${price.toStringAsFixed(2)}',
              style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final String pin;
  const _PinCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PIN de segurança',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(pin,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
      _ctrls.add(ctrl);
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) ctrl.repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrls[i],
              builder: (_, __) {
                final v = _ctrls[i].value;
                return Transform.scale(
                  scale: 0.3 + v * 0.7,
                  child: Opacity(
                    opacity: (1 - v).clamp(0.0, 1.0),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }
}

class _DestinationSheet extends StatelessWidget {
  final void Function(RideLocation) onSelected;
  const _DestinationSheet({required this.onSelected});

  static const _pontos = [
    ('Praia de Saquarema', -22.9280, -42.5105),
    ('Centro de Saquarema', -22.9200, -42.5100),
    ('Lagoa de Saquarema', -22.9350, -42.4950),
    ('Igreja Nossa Sra. de Nazaré', -22.9261, -42.5044),
    ('Hospital Municipal de Saquarema', -22.9210, -42.5090),
    ('Rodoviária de Saquarema', -22.9195, -42.5080),
    ('Praça Orlando de Barros Pimentel', -22.9203, -42.5098),
    ('Bairro Bacaxá', -22.8947, -42.5412),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Text('Para onde você vai?',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _pontos.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (_, i) {
                    final (nome, lat, lng) = _pontos[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.error, size: 18),
                      ),
                      title: Text(nome,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('Saquarema, RJ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      onTap: () => onSelected(RideLocation(address: nome, lat: lat, lng: lng)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
