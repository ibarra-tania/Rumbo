import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/theme.dart';
import '../models/poi.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import 'ui_kit.dart';

/// Panel inferior con el destino seleccionado: distancia en vivo + dirección.
class DestinationPanel extends StatelessWidget {
  const DestinationPanel({
    super.key,
    required this.poi,
    required this.me,
    required this.onClose,
    required this.onFitBoth,
    required this.onDelete,
  });

  final PointOfInterest poi;
  final LatLng? me;
  final VoidCallback onClose;
  final VoidCallback onFitBoth;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final origin = me;
    final meters = origin == null ? null : LocationService.distance(origin, poi.position);
    final bearing = origin == null ? null : LocationService.bearing(origin, poi.position);
    final parts = meters == null ? null : distanceParts(meters);
    final address = poi.address;

    return Panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'DESTINO ${poi.code}',
                  style: mono(size: 11, color: AppColors.coral, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              const SectionLabel('Distancia en vivo', color: AppColors.muted),
              const Spacer(),
              InkResponse(
                onTap: onClose,
                radius: 20,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Distancia grande + rumbo
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (parts == null)
                Text('—', style: t.displaySmall)
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(end: meters!),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    final (v, unit) = distanceParts(value);
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: v,
                            style: t.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: t.titleLarge?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const Spacer(),
              if (bearing != null && meters != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: bearing * math.pi / 180,
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 18,
                            color: AppColors.mint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${compassPoint(bearing)} · ${normalizeBearing(bearing).toStringAsFixed(0)}°',
                          style: mono(size: 13, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatWalkTime(meters),
                      style: t.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Dirección postal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.place_rounded, color: AppColors.coral, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: poi.resolving
                        ? Row(
                            key: const ValueKey('loading'),
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Consultando dirección…',
                                style: t.bodyMedium?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          )
                        : Column(
                            key: ValueKey(address?.line1 ?? 'none'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address?.line1 ?? 'Dirección no disponible',
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (address != null && address.colonia.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Colonia  ',
                                        style: t.labelSmall?.copyWith(
                                          color: AppColors.mint,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: address.colonia, style: t.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                              if (address != null && address.region.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  address.region,
                                  style: t.bodySmall?.copyWith(color: AppColors.muted),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${formatCoordinate(poi.position.latitude, isLatitude: true)}   '
                                '${formatCoordinate(poi.position.longitude, isLatitude: false)}',
                                style: mono(size: 11, color: AppColors.faint),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: origin == null ? null : onFitBoth,
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 19),
                  label: const Text('Ver trayecto'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.coral),
                label: const Text('Quitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
