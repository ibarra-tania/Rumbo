import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app/theme.dart';
import '../services/location_service.dart';
import '../widgets/ui_kit.dart';
import 'map_screen.dart';

enum _GateStatus {
  checking,
  needsPermission,
  serviceDisabled,
  denied,
  deniedForever,
  locating,
}

/// Bienvenida + validación de hardware y permisos antes de abrir el mapa.
class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  _GateStatus _status = _GateStatus.checking;
  bool _busy = false;
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _silentCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _radar.dispose();
    super.dispose();
  }

  /// Al volver de Ajustes, re-validamos automáticamente.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_status == _GateStatus.serviceDisabled ||
            _status == _GateStatus.deniedForever)) {
      _silentCheck();
    }
  }

  Future<void> _silentCheck() async {
    final ok = await LocationService.hasAccessSilently();
    if (!mounted) return;
    if (ok) {
      _enter();
      return;
    }
    final service = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      if (!service) {
        _status = _GateStatus.serviceDisabled;
      } else if (permission == LocationPermission.deniedForever) {
        _status = _GateStatus.deniedForever;
      } else {
        _status = _GateStatus.needsPermission;
      }
    });
  }

  Future<void> _onPrimary() async {
    if (_status == _GateStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    if (_status == _GateStatus.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    setState(() => _busy = true);
    final access = await LocationService.ensureAccess();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (access) {
      case LocationAccess.ready:
        _enter();
      case LocationAccess.serviceDisabled:
        setState(() => _status = _GateStatus.serviceDisabled);
      case LocationAccess.denied:
        setState(() => _status = _GateStatus.denied);
      case LocationAccess.deniedForever:
        setState(() => _status = _GateStatus.deniedForever);
    }
  }

  Future<void> _enter() async {
    if (_entering) return;
    _entering = true;
    setState(() => _status = _GateStatus.locating);

    Position? position;
    try {
      position = await LocationService.currentPosition()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        position = null;
      }
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => MapScreen(initialPosition: position),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  ({String title, String body, String action, IconData icon, Color color})
      get _copy {
    switch (_status) {
      case _GateStatus.checking:
        return (
          title: 'Preparando sensores',
          body: 'Verificando GPS y permisos del dispositivo…',
          action: 'Un momento',
          icon: Icons.hourglass_top_rounded,
          color: AppColors.sky,
        );
      case _GateStatus.needsPermission:
        return (
          title: 'Necesitamos tu ubicación',
          body:
              'La usamos para centrar el mapa, medir distancias en vivo y mostrar direcciones. Nunca sale de tu dispositivo.',
          action: 'Permitir ubicación',
          icon: Icons.my_location_rounded,
          color: AppColors.mint,
        );
      case _GateStatus.denied:
        return (
          title: 'Permiso rechazado',
          body:
              'Sin acceso a la ubicación no podemos mostrarte en el mapa. Puedes intentarlo de nuevo.',
          action: 'Intentar de nuevo',
          icon: Icons.location_disabled_rounded,
          color: AppColors.amber,
        );
      case _GateStatus.deniedForever:
        return (
          title: 'Permiso bloqueado',
          body:
              'El permiso fue denegado de forma permanente. Actívalo en Ajustes › Permisos › Ubicación.',
          action: 'Abrir ajustes',
          icon: Icons.settings_rounded,
          color: AppColors.coral,
        );
      case _GateStatus.serviceDisabled:
        return (
          title: 'El GPS está apagado',
          body:
              'Enciende la ubicación del dispositivo y volveremos automáticamente.',
          action: 'Activar GPS',
          icon: Icons.gps_off_rounded,
          color: AppColors.amber,
        );
      case _GateStatus.locating:
        return (
          title: 'Buscando satélites',
          body: 'Obteniendo tus coordenadas con alta precisión…',
          action: 'Localizando…',
          icon: Icons.satellite_alt_rounded,
          color: AppColors.mint,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final copy = _copy;
    final waiting = _status == _GateStatus.checking ||
        _status == _GateStatus.locating ||
        _busy;

    return Scaffold(
      body: Stack(
        children: [
          // Halos de color de fondo
          Positioned(
            top: -120,
            right: -100,
            child: _Glow(color: AppColors.mint.withValues(alpha: 0.18), size: 320),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _Glow(color: AppColors.sky.withValues(alpha: 0.14), size: 360),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SectionLabel('UTXJ · Semana 10'),
                      const Spacer(),
                      Text('v1.0', style: mono(size: 11, color: AppColors.faint)),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: AnimatedBuilder(
                          animation: _radar,
                          builder: (context, child) => CustomPaint(
                            painter: RadarPainter(_radar.value),
                            child: child,
                          ),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.mint, AppColors.sky],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mint.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.explore_rounded,
                                size: 34,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Rumbo',
                    style: t.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Localizador de puntos de interés con GPS en tiempo real.',
                    style: t.titleMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  const _Feature(
                    icon: Icons.gps_fixed_rounded,
                    color: AppColors.mint,
                    text: 'Tu posición en vivo, filtrada cada 10 m',
                  ),
                  const _Feature(
                    icon: Icons.touch_app_rounded,
                    color: AppColors.coral,
                    text: 'Toca el mapa para marcar destinos',
                  ),
                  const _Feature(
                    icon: Icons.straighten_rounded,
                    color: AppColors.sky,
                    text: 'Distancia exacta, calle y colonia',
                  ),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_status),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: copy.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: copy.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(copy.icon, color: copy.color, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  copy.title,
                                  style: t.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  copy.body,
                                  style: t.bodySmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: waiting ? null : _onPrimary,
                      child: waiting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.mint,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(copy.action),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(copy.action),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Desarrollo Móvil Integral · IDGS',
                      style: t.labelSmall?.copyWith(color: AppColors.faint),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
