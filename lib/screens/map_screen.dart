import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/theme.dart';
import '../map/map_styles.dart';
import '../map/marker_factory.dart';
import '../models/address.dart';
import '../models/poi.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../utils/format.dart';
import '../widgets/destination_panel.dart';
import '../widgets/my_location_panel.dart';
import '../widgets/poi_list_sheet.dart';
import '../widgets/ui_kit.dart';

/// Pantalla principal: mapa interactivo + GPS en vivo + puntos de interés.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialPosition});

  final Position? initialPosition;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Respaldo si aún no hay GPS: UTXJ, Xicotepec de Juárez.
  static const LatLng _utxj = LatLng(20.2756, -97.9611);

  GoogleMapController? _map;
  StreamSubscription<Position>? _positionSub;

  Position? _me;
  Address? _myAddress;
  LatLng? _lastGeocodedMe;
  bool _resolvingMe = false;

  final List<PointOfInterest> _pois = [];
  final Map<String, BitmapDescriptor> _icons = {};
  String? _selectedId;
  int _counter = 0;

  MapLook _look = MapLook.nocturno;
  bool _follow = false;
  bool _gpsLost = false;

  LatLng? get _meLatLng =>
      _me == null ? null : LatLng(_me!.latitude, _me!.longitude);

  PointOfInterest? get _selected {
    for (final p in _pois) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  // ───────────────────────── Ciclo de vida ─────────────────────────

  @override
  void initState() {
    super.initState();
    _me = widget.initialPosition;
    _positionSub = LocationService.positionStream().listen(
      _onPosition,
      onError: _onPositionError,
    );
    _resolveMyAddress(force: true);
  }

  @override
  void dispose() {
    // Liberamos recursos: stream del GPS y controlador del mapa.
    _positionSub?.cancel();
    _map?.dispose();
    super.dispose();
  }

  // ───────────────────────── GPS en tiempo real ─────────────────────────

  void _onPosition(Position p) {
    if (!mounted) return;
    setState(() {
      _me = p;
      _gpsLost = false;
    });
    if (_follow) {
      _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)),
      );
    }
    _resolveMyAddress();
  }

  void _onPositionError(Object error) {
    if (!mounted) return;
    setState(() => _gpsLost = true);
    _toast(
      error is LocationServiceDisabledException
          ? 'El GPS se desactivó. Enciéndelo para seguir en vivo.'
          : 'Se perdió la señal de ubicación.',
      icon: Icons.gps_off_rounded,
    );
  }

  Future<void> _resolveMyAddress({bool force = false}) async {
    final me = _meLatLng;
    if (me == null || _resolvingMe) return;
    final last = _lastGeocodedMe;
    if (!force && last != null && LocationService.distance(last, me) < 40) {
      return;
    }
    _resolvingMe = true;
    final address = await GeocodingService.reverse(me);
    _resolvingMe = false;
    if (!mounted) return;
    setState(() {
      _myAddress = address ?? _myAddress;
      _lastGeocodedMe = me;
    });
  }

  // ───────────────────────── Cámara ─────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _map = controller;
    // Requisito 1: centrar la cámara en el usuario al iniciar.
    Future.delayed(const Duration(milliseconds: 400), _centerOnMe);
  }

  Future<void> _centerOnMe() async {
    var me = _meLatLng;
    if (me == null) {
      try {
        final p = await LocationService.currentPosition();
        if (!mounted) return;
        setState(() => _me = p);
        me = _meLatLng;
      } catch (_) {
        _toast('Aún no tenemos tu ubicación.', icon: Icons.gps_not_fixed_rounded);
        return;
      }
    }
    if (me == null) return;
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: me, zoom: 17, tilt: 30),
      ),
    );
  }

  void _toggleFollow() {
    HapticFeedback.lightImpact();
    setState(() => _follow = !_follow);
    if (_follow) _centerOnMe();
    _toast(
      _follow ? 'Modo seguimiento activado' : 'Modo seguimiento desactivado',
      icon: Icons.navigation_rounded,
    );
  }

  void _fitBoth() {
    final me = _meLatLng;
    final dest = _selected?.position;
    if (me == null || dest == null) return;
    HapticFeedback.lightImpact();
    if (LocationService.distance(me, dest) < 5) {
      _map?.animateCamera(CameraUpdate.newLatLngZoom(dest, 18));
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(me.latitude, dest.latitude),
        math.min(me.longitude, dest.longitude),
      ),
      northeast: LatLng(
        math.max(me.latitude, dest.latitude),
        math.max(me.longitude, dest.longitude),
      ),
    );
    setState(() => _follow = false);
    _map?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  void _cycleLook() {
    HapticFeedback.selectionClick();
    setState(() => _look = _look.next);
    _toast('Mapa ${_look.label}', icon: _look.icon);
  }

  // ───────────────────────── Puntos de interés ─────────────────────────

  /// Requisito 2: crear un pin al tocar cualquier punto del mapa.
  Future<void> _addPoi(LatLng point) async {
    HapticFeedback.selectionClick();
    final dpr = MediaQuery.of(context).devicePixelRatio;
    _counter++;
    final poi = PointOfInterest(
      id: 'poi_$_counter',
      number: _counter,
      position: point,
    );
    setState(() {
      _pois.add(poi);
      _selectedId = poi.id;
      _follow = false;
    });
    _buildIcons(poi, dpr);
    await _resolvePoi(poi);
  }

  Future<void> _buildIcons(PointOfInterest poi, double dpr) async {
    final normal = await MarkerFactory.pin(
      color: AppColors.sky,
      label: poi.code,
      devicePixelRatio: dpr,
      fallbackHue: BitmapDescriptor.hueAzure,
    );
    final selected = await MarkerFactory.pin(
      color: AppColors.coral,
      label: poi.code,
      devicePixelRatio: dpr,
      fallbackHue: BitmapDescriptor.hueRed,
    );
    if (!mounted) return;
    setState(() {
      _icons['${poi.id}:n'] = normal;
      _icons['${poi.id}:s'] = selected;
    });
  }

  /// Requisito 4: dirección postal (calle y colonia) por geocodificación inversa.
  Future<void> _resolvePoi(PointOfInterest poi) async {
    setState(() => poi.resolving = true);
    final address = await GeocodingService.reverse(poi.position);
    if (!mounted) return;
    setState(() {
      poi.address = address;
      poi.resolving = false;
    });
  }

  void _movePoi(PointOfInterest poi, LatLng position) {
    HapticFeedback.mediumImpact();
    setState(() {
      poi.position = position;
      _selectedId = poi.id;
    });
    _resolvePoi(poi);
  }

  void _selectPoi(PointOfInterest poi, {bool animate = true}) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedId = poi.id;
      _follow = false;
    });
    if (animate) {
      _map?.animateCamera(CameraUpdate.newLatLngZoom(poi.position, 17));
    }
  }

  void _removePoi(PointOfInterest poi) {
    HapticFeedback.mediumImpact();
    setState(() {
      _pois.removeWhere((p) => p.id == poi.id);
      _icons.remove('${poi.id}:n');
      _icons.remove('${poi.id}:s');
      if (_selectedId == poi.id) _selectedId = null;
    });
  }

  void _openList() {
    showPoiSheet(
      context: context,
      pois: _pois,
      me: () => _meLatLng,
      onSelect: _selectPoi,
      onDelete: _removePoi,
    );
  }

  Future<void> _copyMyCoordinates() async {
    final me = _me;
    if (me == null) return;
    await Clipboard.setData(
      ClipboardData(
        text: '${me.latitude.toStringAsFixed(6)}, ${me.longitude.toStringAsFixed(6)}',
      ),
    );
    _toast('Coordenadas copiadas', icon: Icons.copy_rounded);
  }

  void _toast(String message, {IconData icon = Icons.info_outline_rounded}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mint),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Capas del mapa ─────────────────────────

  Set<Marker> _buildMarkers() {
    final me = _meLatLng;
    return _pois.map((p) {
      final isSelected = p.id == _selectedId;
      final icon = _icons['${p.id}:${isSelected ? 's' : 'n'}'] ??
          BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
          );
      final d = me == null ? null : LocationService.distance(me, p.position);
      final snippet = [
        if (d != null) formatDistance(d),
        if ((p.address?.colonia ?? '').isNotEmpty) p.address!.colonia,
      ].join(' · ');

      return Marker(
        markerId: MarkerId(p.id),
        position: p.position,
        icon: icon,
        anchor: MarkerFactory.anchor,
        zIndex: isSelected ? 10.0 : 1.0,
        draggable: true,
        infoWindow: InfoWindow(
          title: p.title,
          snippet: snippet.isEmpty ? null : snippet,
        ),
        onTap: () => _selectPoi(p, animate: false),
        onDragEnd: (pos) => _movePoi(p, pos),
      );
    }).toSet();
  }

  Set<Polyline> _buildPolylines() {
    final me = _meLatLng;
    final dest = _selected?.position;
    if (me == null || dest == null) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('trayecto'),
        points: [me, dest],
        color: AppColors.mint,
        width: 5,
        geodesic: true,
        patterns: [PatternItem.dash(24), PatternItem.gap(14)],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Circle> _buildCircles() {
    final me = _me;
    if (me == null) return const {};
    return {
      Circle(
        circleId: const CircleId('precision'),
        center: LatLng(me.latitude, me.longitude),
        radius: me.accuracy.clamp(5, 500).toDouble(),
        fillColor: AppColors.mint.withValues(alpha: 0.10),
        strokeColor: AppColors.mint.withValues(alpha: 0.55),
        strokeWidth: 1,
      ),
    };
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final selected = _selected;
    final initialTarget = _meLatLng ?? _utxj;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15.5,
            ),
            onMapCreated: _onMapCreated,
            style: _look.style,
            mapType: _look.mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            circles: _buildCircles(),
            onTap: _addPoi,
            padding: EdgeInsets.only(
              top: media.padding.top + 80,
              bottom: selected == null ? 290 : 320,
            ),
          ),

          // Degradado superior para legibilidad
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: media.padding.top + 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.ink.withValues(alpha: 0.9),
                      AppColors.ink.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Barra superior
          Positioned(
            top: media.padding.top + 10,
            left: 14,
            right: 14,
            child: _TopBar(
              live: !_gpsLost && _me != null,
              accuracy: _me?.accuracy,
              look: _look,
              onLook: _cycleLook,
            ),
          ),

          // Acciones flotantes + panel inferior
          Positioned(
            left: 12,
            right: 12,
            bottom: media.padding.bottom + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoundAction(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Puntos de interés',
                      badge: _pois.length,
                      onPressed: _openList,
                    ),
                    const SizedBox(height: 10),
                    RoundAction(
                      icon: Icons.navigation_rounded,
                      tooltip: 'Seguirme',
                      active: _follow,
                      onPressed: _toggleFollow,
                    ),
                    const SizedBox(height: 10),
                    RoundAction(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Centrar en mí',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _centerOnMe();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: selected == null
                      ? MyLocationPanel(
                          key: const ValueKey('me'),
                          position: _me,
                          address: _myAddress,
                          onCopy: _copyMyCoordinates,
                        )
                      : DestinationPanel(
                          key: ValueKey(selected.id),
                          poi: selected,
                          me: _meLatLng,
                          onClose: () => setState(() => _selectedId = null),
                          onFitBoth: _fitBoth,
                          onDelete: () => _removePoi(selected),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.live,
    required this.accuracy,
    required this.look,
    required this.onLook,
  });

  final bool live;
  final double? accuracy;
  final MapLook look;
  final VoidCallback onLook;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.mint, AppColors.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.explore_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rumbo',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                LiveBadge(live: live, accuracy: accuracy),
              ],
            ),
          ),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onLook,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(look.icon, size: 18, color: AppColors.mint),
                    const SizedBox(width: 6),
                    Text(
                      look.label,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
