import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/address.dart';

/// Geocodificación inversa: coordenadas → calle, colonia, ciudad.
class GeocodingService {
  GeocodingService._();

  static final Geocoding _geocoding = Geocoding(locale: const Locale('es', 'MX'));
  static final Map<String, Address> _cache = {};
  static final RegExp _plusCode =
      RegExp(r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{2,}');

  static Future<Address?> reverse(LatLng point) async {
    final key =
        '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final placemarks =
          await _geocoding.placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isEmpty) return null;

      final address = _fromPlacemark(placemarks.first);
      _cache[key] = address;
      return address;
    } catch (_) {
      return null;
    }
  }

  static Address _fromPlacemark(Placemark p) {
    String clean(String? s) {
      final v = (s ?? '').trim();
      return _plusCode.hasMatch(v) ? '' : v;
    }

    final thoroughfare = clean(p.thoroughfare);
    final number = clean(p.subThoroughfare);
    var street = [thoroughfare, number].where((e) => e.isNotEmpty).join(' ');
    if (street.isEmpty) street = clean(p.street);
    if (street.isEmpty) street = clean(p.name);

    final city = clean(p.locality).isNotEmpty
        ? clean(p.locality)
        : clean(p.subAdministrativeArea);

    return Address(
      street: street,
      colonia: clean(p.subLocality),
      city: city,
      state: clean(p.administrativeArea),
      postalCode: clean(p.postalCode),
    );
  }
}
