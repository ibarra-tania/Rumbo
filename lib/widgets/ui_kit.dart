import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Tarjeta flotante sobre el mapa.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // Material transparente: los efectos Ink/InkWell se pintan dentro del panel
      // (y no detrás del mapa, que es una vista nativa).
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Etiqueta de sección en mayúsculas con tracking amplio.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.mint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Botón circular flotante del mapa.
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.active = false,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool active;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: active ? AppColors.mint : AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      elevation: 6,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            size: 22,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badge != null && badge! > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dato compacto: ícono + etiqueta + valor.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.sky,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono(size: 14, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador "EN VIVO" con punto pulsante.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, required this.live, this.accuracy});

  final bool live;
  final double? accuracy;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.live ? AppColors.mint : AppColors.coral;
    final acc = widget.accuracy;
    final text = widget.live
        ? (acc != null ? 'EN VIVO · ±${acc.toStringAsFixed(0)} m' : 'EN VIVO')
        : 'SIN SEÑAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final v = _c.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 6 + 6 * v,
                      height: 6 + 6 * v,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.5 * (1 - v)),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: mono(size: 10.5, color: color, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Radar animado para la pantalla de bienvenida.
class RadarPainter extends CustomPainter {
  RadarPainter(this.t);

  /// Progreso de la animación 0..1
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Anillos fijos
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.line;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(c, maxR * i / 4, ring);
    }
    // Cruz
    canvas.drawLine(Offset(c.dx - maxR, c.dy), Offset(c.dx + maxR, c.dy), ring);
    canvas.drawLine(Offset(c.dx, c.dy - maxR), Offset(c.dx, c.dy + maxR), ring);

    // Barrido
    final rect = Rect.fromCircle(center: c, radius: maxR);
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.mint.withValues(alpha: 0),
          AppColors.mint.withValues(alpha: 0),
          AppColors.mint.withValues(alpha: 0.38),
        ],
        stops: const [0, 0.72, 1],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(rect);
    canvas.drawCircle(c, maxR, sweep);

    // Pulsos expansivos
    for (var k = 0; k < 3; k++) {
      final p = (t + k / 3) % 1;
      canvas.drawCircle(
        c,
        maxR * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.mint.withValues(alpha: (1 - p) * 0.55),
      );
    }

    // "Puntos de interés" detectados
    const blips = [
      (0.55, 0.9, AppColors.coral),
      (0.78, 3.6, AppColors.sky),
      (0.35, 5.1, AppColors.amber),
    ];
    for (final (dist, angle, color) in blips) {
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * maxR * dist;
      final sweepAngle = (t * 2 * math.pi) % (2 * math.pi);
      final a = (angle % (2 * math.pi));
      final since = (sweepAngle - a) % (2 * math.pi);
      final glow = 1 - (since / (2 * math.pi));
      canvas.drawCircle(
        pos,
        9 * glow,
        Paint()..color = color.withValues(alpha: 0.25 * glow),
      );
      canvas.drawCircle(
        pos,
        3.5,
        Paint()..color = color.withValues(alpha: 0.4 + 0.6 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => oldDelegate.t != t;
}
