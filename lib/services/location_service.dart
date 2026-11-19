import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Resultado de validar hardware + permisos.
enum LocationAccess { ready, serviceDisabled, denied, deniedForever }

/// Encapsula el Fused Location Provider expuesto por geolocator.
class LocationService {
  LocationService._();

  /// Filtro de distancia: solo emite si el usuario se movió ≥ 10 m (ahorra batería).
  static const int distanceFilterMeters = 10;

  /// Validaciones críticas: GPS encendido (hardware) y permiso en runtime.
  static Future<LocationAccess> ensureAccess() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationAccess.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAccess.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationAccess.denied;
    }
    return LocationAccess.ready;
  }

  /// ¿Ya tenemos todo sin necesidad de preguntar?
  static Future<bool> hasAccessSilently() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Lectura puntual con alta precisión.
  static Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Flujo continuo de coordenadas en tiempo real.
  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Distancia geodésica en metros (Geolocator.distanceBetween).
  static double distance(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  /// Rumbo inicial de A hacia B en grados (-180..180).
  static double bearing(LatLng a, LatLng b) {
    return Geolocator.bearingBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
