/// Distancia legible: "850 m", "1.24 km", "12.4 km".
String formatDistance(double meters) {
  final (value, unit) = distanceParts(meters);
  return '$value $unit';
}

/// Separa número y unidad para mostrarlos con estilos distintos.
(String, String) distanceParts(double meters) {
  if (meters < 1000) return (meters.toStringAsFixed(0), 'm');
  final km = meters / 1000;
  return (km.toStringAsFixed(km < 10 ? 2 : 1), 'km');
}

/// Tiempo caminando estimado (~4.8 km/h = 80 m/min).
String formatWalkTime(double meters) {
  final minutes = (meters / 80).ceil();
  if (minutes < 1) return 'Llegaste';
  if (minutes < 60) return '$minutes min a pie';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h a pie' : '$h h $m min a pie';
}

/// 20.27560° N  /  97.96110° O
String formatCoordinate(double value, {required bool isLatitude}) {
  final hemisphere = isLatitude
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'O');
  return '${value.abs().toStringAsFixed(5)}° $hemisphere';
}

/// Normaliza un rumbo (-180..180) a 0..360.
double normalizeBearing(double bearing) => (bearing + 360) % 360;

/// Punto cardinal en español para un rumbo en grados.
String compassPoint(double bearing) {
  const points = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
  final b = normalizeBearing(bearing);
  return points[((b + 22.5) ~/ 45) % 8];
}
