import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Apariencias del mapa que el usuario puede alternar.
enum MapLook { nocturno, claro, satelite }

extension MapLookX on MapLook {
  String get label => switch (this) {
        MapLook.nocturno => 'Nocturno',
        MapLook.claro => 'Claro',
        MapLook.satelite => 'Satélite',
      };

  IconData get icon => switch (this) {
        MapLook.nocturno => Icons.dark_mode_rounded,
        MapLook.claro => Icons.light_mode_rounded,
        MapLook.satelite => Icons.satellite_alt_rounded,
      };

  MapType get mapType =>
      this == MapLook.satelite ? MapType.hybrid : MapType.normal;

  String? get style => switch (this) {
        MapLook.nocturno => kNightStyle,
        MapLook.claro => kLightStyle,
        MapLook.satelite => null,
      };

  MapLook get next => MapLook.values[(index + 1) % MapLook.values.length];
}

/// Estilo propio "Rumbo Nocturno": azul noche con parques verde menta.
const String kNightStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0e1729"}]},
  {"elementType":"labels.icon","stylers":[{"saturation":-60},{"lightness":-20}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8d9ab8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#080e1c"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#26334f"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c3cde6"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#111c31"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#121f37"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f7d9c"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0d2a2a"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#34e5b0"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1b2846"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0b1222"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9aa8c7"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#22345a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2b4a72"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#10203a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#d4def5"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#16223b"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#5aa9ff"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#06162d"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d5a8a"}]}
]
''';

/// Estilo propio "Rumbo Claro": papel limpio, tonos suaves.
const String kLightStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f4f6fb"}]},
  {"elementType":"labels.icon","stylers":[{"saturation":-50}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#56627d"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#e9edf5"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#d3f5e9"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#1f9e78"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dbe6fb"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#b9cdf2"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#e6eaf2"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c7dcf7"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5b7fb5"}]}
]
''';
