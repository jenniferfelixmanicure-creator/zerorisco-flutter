import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';

class AppMapWidget extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final LatLng? driverLocation;
  final List<LatLng> routeCoords;
  final bool isDriver;

  const AppMapWidget({
    super.key,
    this.origin,
    this.destination,
    this.driverLocation,
    this.routeCoords = const [],
    this.isDriver = false,
  });

  @override
  State<AppMapWidget> createState() => _AppMapWidgetState();
}

class _AppMapWidgetState extends State<AppMapWidget> {
  final MapController _mapController = MapController();

  static const _defaultCenter = LatLng(-22.9200, -42.5100);

  LatLng get _center {
    if (widget.driverLocation != null) return widget.driverLocation!;
    if (widget.origin != null) return widget.origin!;
    return _defaultCenter;
  }

  @override
  void didUpdateWidget(AppMapWidget old) {
    super.didUpdateWidget(old);
    if (widget.driverLocation != null &&
        widget.driverLocation != old.driverLocation) {
      _mapController.move(widget.driverLocation!, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 15,
        minZoom: 5,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.zerorisco.app',
          maxZoom: 19,
        ),
        if (widget.routeCoords.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routeCoords,
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.origin != null)
              Marker(
                point: widget.origin!,
                width: 24,
                height: 24,
                child: _Dot(color: AppColors.primary),
              ),
            if (widget.destination != null)
              Marker(
                point: widget.destination!,
                width: 32,
                height: 32,
                child: const _PinMarker(color: AppColors.error),
              ),
            if (widget.driverLocation != null)
              Marker(
                point: widget.driverLocation!,
                width: 40,
                height: 40,
                child: _DriverMarker(isDriver: widget.isDriver),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  final Color color;
  const _PinMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_pin, color: color, size: 32);
  }
}

class _DriverMarker extends StatelessWidget {
  final bool isDriver;
  const _DriverMarker({required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
