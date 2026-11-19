import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'address.dart';

/// Punto de interés creado al tocar el mapa.
class PointOfInterest {
  PointOfInterest({
    required this.id,
    required this.number,
    required this.position,
  }) : createdAt = DateTime.now();

  final String id;
  final int number;
  final DateTime createdAt;

  LatLng position;
  Address? address;
  bool resolving = true;

  String get code => number.toString().padLeft(2, '0');

  String get title {
    final street = address?.street ?? '';
    return street.isNotEmpty ? street : 'Punto $code';
  }
}
