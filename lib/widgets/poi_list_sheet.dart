import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/theme.dart';
import '../models/poi.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import 'ui_kit.dart';

/// Hoja inferior con todos los puntos de interés, ordenados por cercanía.
Future<void> showPoiSheet({
  required BuildContext context,
  required List<PointOfInterest> pois,
  required LatLng? Function() me,
  required void Function(PointOfInterest poi) onSelect,
  required void Function(PointOfInterest poi) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final t = Theme.of(sheetContext).textTheme;
          final origin = me();
          final items = [...pois];
          if (origin != null) {
            items.sort((a, b) => LocationService.distance(origin, a.position)
                .compareTo(LocationService.distance(origin, b.position)));
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('Ordenados por cercanía'),
                              const SizedBox(height: 4),
                              Text(
                                'Puntos de interés',
                                style: t.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${items.length}',
                          style: mono(size: 26, color: AppColors.mint, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Row(
                        children: [
                          const Icon(Icons.add_location_alt_rounded,
                              color: AppColors.faint, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aún no hay puntos. Toca cualquier lugar del mapa para crear el primero.',
                              style: t.bodyMedium?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final poi = items[i];
                          final d = origin == null
                              ? null
                              : LocationService.distance(origin, poi.position);
                          return Dismissible(
                            key: ValueKey(poi.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_rounded,
                                  color: AppColors.coral),
                            ),
                            onDismissed: (_) {
                              onDelete(poi);
                              setSheet(() {});
                            },
                            child: Material(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  onSelect(poi);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.sky.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          poi.code,
                                          style: mono(
                                            size: 14,
                                            color: AppColors.sky,
                                            weight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              poi.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              poi.resolving
                                                  ? 'Consultando dirección…'
                                                  : (poi.address?.line2.isNotEmpty ?? false)
                                                      ? poi.address!.line2
                                                      : formatCoordinate(
                                                          poi.position.latitude,
                                                          isLatitude: true),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodySmall
                                                  ?.copyWith(color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        d == null ? '—' : formatDistance(d),
                                        style: mono(size: 13, weight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
