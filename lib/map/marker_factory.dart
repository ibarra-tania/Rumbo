import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/theme.dart';

/// Dibuja pines personalizados (con número) en Canvas y los convierte
/// en BitmapDescriptor para usarlos como íconos de Marker.
class MarkerFactory {
  MarkerFactory._();

  static const double _w = 46;
  static const double _h = 60;
  static const double _tipY = _h - 6;

  /// Punto del bitmap que toca la coordenada (la punta del pin).
  static const Offset anchor = Offset(0.5, _tipY / _h);

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> pin({
    required Color color,
    required String label,
    required double devicePixelRatio,
    double fallbackHue = BitmapDescriptor.hueAzure,
  }) async {
    final dpr = devicePixelRatio.clamp(1.0, 4.0).toDouble();
    final key = '${color.toARGB32()}|$label|$dpr';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(dpr);

      const cx = _w / 2;
      const cy = 21.0;
      const r = 18.0;

      // Sombra en el suelo
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(cx, _tipY), width: 16, height: 5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Silueta del pin = círculo + punta
      final circle = Path()
        ..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r));
      final tip = Path()
        ..moveTo(cx - 10, cy + 12)
        ..quadraticBezierTo(cx - 3, cy + 22, cx, _tipY)
        ..quadraticBezierTo(cx + 3, cy + 22, cx + 10, cy + 12)
        ..close();
      final pinPath = Path.combine(PathOperation.union, circle, tip);

      canvas.drawPath(pinPath, Paint()..color = color);
      canvas.drawPath(
        pinPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white,
      );

      // Núcleo oscuro con el número
      canvas.drawCircle(
        const Offset(cx, cy),
        12.5,
        Paint()..color = AppColors.ink,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

      final image = await recorder
          .endRecording()
          .toImage((_w * dpr).round(), (_h * dpr).round());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG vacío');

      final descriptor = BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        imagePixelRatio: dpr,
      );
      _cache[key] = descriptor;
      return descriptor;
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }
  }
}
