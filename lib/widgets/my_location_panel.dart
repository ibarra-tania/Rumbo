import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app/theme.dart';
import '../models/address.dart';
import '../utils/format.dart';
import 'ui_kit.dart';

/// Panel inferior cuando no hay destino seleccionado: datos del usuario en vivo.
class MyLocationPanel extends StatelessWidget {
  const MyLocationPanel({
    super.key,
    required this.position,
    required this.address,
    required this.onCopy,
  });

  final Position? position;
  final Address? address;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = position;

    return Panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Tu ubicación en vivo'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address?.line1 ??
                          (p == null ? 'Esperando señal GPS…' : 'Buscando dirección…'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (address?.line2.isNotEmpty ?? false)
                          ? address!.line2
                          : 'Geocodificación inversa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Coordenadas
          InkWell(
            onTap: p == null ? null : onCopy,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Coord(
                      label: 'LAT',
                      value: p == null
                          ? '—'
                          : formatCoordinate(p.latitude, isLatitude: true),
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.line),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _Coord(
                      label: 'LNG',
                      value: p == null
                          ? '—'
                          : formatCoordinate(p.longitude, isLatitude: false),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.faint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatChip(
                icon: Icons.adjust_rounded,
                label: 'Precisión',
                value: p == null ? '—' : '±${p.accuracy.toStringAsFixed(0)} m',
                color: AppColors.mint,
              ),
              const SizedBox(width: 8),
              StatChip(
                icon: Icons.speed_rounded,
                label: 'Velocidad',
                value: p == null
                    ? '—'
                    : '${(p.speed * 3.6).clamp(0, 999).toStringAsFixed(1)} km/h',
              ),
              const SizedBox(width: 8),
              StatChip(
                icon: Icons.terrain_rounded,
                label: 'Altitud',
                value: p == null ? '—' : '${p.altitude.toStringAsFixed(0)} m',
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.coral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toca el mapa para marcar un destino. Mantén presionado un pin para moverlo.',
                  style: t.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Coord extends StatelessWidget {
  const _Coord({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: mono(size: 10, color: AppColors.faint)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mono(size: 13.5, weight: FontWeight.w700),
        ),
      ],
    );
  }
}
