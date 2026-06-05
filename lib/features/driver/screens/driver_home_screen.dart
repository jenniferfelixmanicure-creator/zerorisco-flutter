import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/app_map_widget.dart';
import '../../shared/widgets/sos_button.dart';
import '../../shared/widgets/ride_chat_widget.dart';
import '../providers/driver_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AppMapWidget(
            origin: driver.myLocation,
            destination: driver.activeRide != null
                ? LatLng(
                    driver.activeRide!.destination.lat,
                    driver.activeRide!.destination.lng,
                  )
                : null,
            driverLocation: driver.myLocation,
            isDriver: true,
          ),

          _buildTopBar(context, driver, auth),

          if (driver.status == DriverStatus.activeRide)
            SosButton(onActivated: () {
              if (driver.activeRide != null) {
                context.read<DriverProvider>();
              }
            }),

          if (_showChat && driver.activeRide != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showChat = false),
                child: Container(color: Colors.black54),
              ),
            ),

          if (_showChat && driver.activeRide != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: RideChatWidget(
                myId: auth.user?.id ?? '',
                myName: auth.user?.name ?? '',
                otherName: 'Passageiro',
                messages: driver.chatMessages,
                onSend: (text) => driver.sendChatMessage(
                  driver.activeRide!.id,
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
              child: _buildBottomPanel(context, driver, auth),
            ),

          if (driver.status == DriverStatus.hasRequest && driver.incomingRequest != null)
            _RequestOverlay(
              request: driver.incomingRequest!,
              onAccept: () => driver.acceptRequest(),
              onReject: () => driver.rejectRequest(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    DriverProvider driver,
    AuthProvider auth,
  ) {
    final isOnline = driver.status != DriverStatus.offline;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (isOnline) {
                    driver.goOffline(auth.user?.id ?? '');
                  } else {
                    driver.goOnline(
                      auth.user?.id ?? '',
                      auth.user?.name ?? '',
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isOnline ? AppColors.success : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline ? AppColors.success : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    DriverProvider driver,
    AuthProvider auth,
  ) {
    return switch (driver.status) {
      DriverStatus.offline => _buildOfflinePanel(),
      DriverStatus.online => _buildOnlinePanel(),
      DriverStatus.hasRequest => const SizedBox.shrink(),
      DriverStatus.activeRide => _buildActiveRidePanel(context, driver, auth),
    };
  }

  Widget _buildOfflinePanel() {
    return _BottomSheetContainer(
      children: [
        const _Handle(),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textMuted.withOpacity(0.1),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.textMuted,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você está offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ative o botão Online para receber corridas',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOnlinePanel() {
    return _BottomSheetContainer(
      children: [
        const _Handle(),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              _PulsingDot(),
              const SizedBox(height: 12),
              const Text(
                'Aguardando corridas...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Você está online e visível para passageiros próximos',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActiveRidePanel(
    BuildContext context,
    DriverProvider driver,
    AuthProvider auth,
  ) {
    final ride = driver.activeRide;
    if (ride == null) return const SizedBox.shrink();

    return _BottomSheetContainer(
      children: [
        const _Handle(),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Corrida em andamento',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              'R\$ ${ride.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _RouteRow(
                icon: Icons.circle,
                iconColor: AppColors.primary,
                label: ride.origin.address,
              ),
              const SizedBox(height: 10),
              _RouteRow(
                icon: Icons.location_pin,
                iconColor: AppColors.error,
                label: ride.destination.address,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (ride.pin != null) ...[
          _PinCard(pin: ride.pin!),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  driver.clearUnread();
                  setState(() => _showChat = true);
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_rounded, size: 18),
                    if (driver.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                          child: Text(
                            '${driver.unreadCount}',
                            style: const TextStyle(fontSize: 9, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: const Text('Chat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => driver.completeTrip(),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Concluir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RequestOverlay extends StatelessWidget {
  final IncomingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestOverlay({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _RequestCard(
              request: request,
              onAccept: onAccept,
              onReject: onReject,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final IncomingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countdown = context.watch<DriverProvider>().countdownSeconds;
    final progress = countdown / 30.0;
    final rideType = RideType.values.firstWhere(
      (t) => t.value == widget.request.rideType,
      orElse: () => RideType.basico,
    );

    return SlideTransition(
      position: _slide,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  progress > 0.5
                      ? AppColors.success
                      : progress > 0.2
                          ? AppColors.warning
                          : AppColors.error,
                ),
                minHeight: 5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nova corrida — ${rideType.label}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.request.passengerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${widget.request.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            '${countdown}s',
                            style: TextStyle(
                              color: countdown <= 10 ? AppColors.error : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _RouteRow(
                          icon: Icons.circle,
                          iconColor: AppColors.primary,
                          label: widget.request.origin.address,
                        ),
                        const SizedBox(height: 8),
                        _RouteRow(
                          icon: Icons.location_pin,
                          iconColor: AppColors.error,
                          label: widget.request.destination.address,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.straighten_rounded, label: widget.request.distance),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.timer_outlined, label: widget.request.duration),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onReject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shadowColor: AppColors.success.withOpacity(0.4),
                            elevation: 8,
                          ),
                          child: const Text('Aceitar corrida'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final List<Widget> children;
  const _BottomSheetContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
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

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 16 + _anim.value * 4,
        height: 16 + _anim.value * 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withOpacity(0.7 + _anim.value * 0.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 12 + _anim.value * 8,
              spreadRadius: _anim.value * 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _RouteRow({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PIN de verificação', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                pin,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
