import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/location_permission_helper.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/screens/next_where_to_screen.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/widgets/profile_bottom_sheet.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/services/notification_service.dart';
import 'package:mapy/services/voice_navigation_service.dart';
import 'package:mapy/services/location_share_service.dart';
import 'package:mapy/features/map/utils/map_icon_helper.dart';
import 'package:mapy/features/map/utils/map_layer_manager.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/features/map/widgets/map_controls_overlay.dart';
import 'package:mapy/features/map/widgets/navigation_overlay.dart';
import 'package:mapy/features/map/widgets/route_alternatives_sheet.dart';
import 'package:mapy/blocs/map/map_cubit.dart';
import 'package:mapy/blocs/map/map_state.dart';

class MainMapScreen extends StatefulWidget {
  final String userName;

  const MainMapScreen({super.key, required this.userName});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  late final MapCubit _mapCubit;

  @override
  void initState() {
    super.initState();
    _mapCubit = MapCubit();
    _initialize();
  }

  Future<void> _initialize() async {
    await _mapCubit.initialize();
    NotificationService.initialize();
    await VoiceNavigationService.initialize();
    _mapCubit.startLocationTracking();
    await _relocateMe();
  }

  @override
  void dispose() {
    _mapCubit.close();
    super.dispose();
  }

  // ── Map callbacks ──────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapCubit.setMapController(controller);
    _relocateMe();
  }

  Future<void> _onStyleLoaded() async {
    await MapIconHelper.addStandardIcons(_mapCubit.mapController!);
    await _mapCubit.updateLayers(force: true);
  }

  void _onCameraIdle() {
    if (mounted && _mapCubit.mapController != null) {
      _mapCubit.mapController!.getVisibleRegion();
      _mapCubit.updateBearing(
          _mapCubit.mapController!.cameraPosition?.bearing ?? 0.0);
    }
  }

  void _onMapClick(dynamic point, LatLng latlng) {
    if (!_mapCubit.state.isNavigating) {
      _mapCubit.navigateTo(latlng);
    }
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _relocateMe() async {
    final result = await LocationPermissionHelper.requestPermission();
    if (!result.granted) {
      if (!mounted) return;
      _showSnackBar(result.errorMessage ?? 'Location error');
      return;
    }

    try {
      final position = await _mapCubit.getCurrentPosition();
      if (position == null || !mounted) return;
      setState(() {});
      _mapCubit.mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 18.0, tilt: 45),
        ),
        duration: const Duration(milliseconds: 1200),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Location Error: $e');
    }
  }

  // ── Navigation / route actions ─────────────────────────────────────────────

  Future<void> _onWhereToTapped() async {
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(builder: (_) => const NextWhereToScreen()),
    );
    if (picked == null || !mounted) return;
    await _mapCubit.loadHistory();
    final loc = LatLng(picked.latitude, picked.longitude);
    await _mapCubit.navigateTo(loc);
    setState(() {});
  }

  Future<void> _toggleNavigation() async {
    await _mapCubit.toggleNavigation();
    if (_mapCubit.state.isNavigating &&
        _mapCubit.state.currentLocation != null) {
      _mapCubit.startLocationTracking();
    }
    setState(() {});
  }

  void _clearRoute() {
    _mapCubit.clearRoute();
    setState(() {});
  }

  void _setTravelMode(TravelMode mode) {
    _mapCubit.setTravelMode(mode);
  }

  void _toggleMapPerspective() {
    _mapCubit.toggleMapPerspective();
    setState(() {});
  }

  // ── Home / Work ────────────────────────────────────────────────────────────

  void _handleLocationButton(String type) {
    final loc = type == 'home'
        ? _mapCubit.state.homeLocation
        : _mapCubit.state.workLocation;
    if (loc == null) {
      _openPicker(type);
    } else {
      final locLibre = loc.toLibre();
      LocationActionSheet.show(
        context: context,
        type: type,
        latitude: locLibre.latitude,
        longitude: locLibre.longitude,
        onNavigate: () {
          _mapCubit.navigateTo(locLibre);
          setState(() {});
        },
        onChange: () => _openPicker(type),
        onClear: () async {
          final error = type == 'home'
              ? await _mapCubit.clearHomeLocation()
              : await _mapCubit.clearWorkLocation();

          if (!mounted) return;
          if (error != null) {
            _showSnackBar('Failed to clear location: $error',
                color: Colors.redAccent);
            return;
          }
          _showSnackBar(
              '${type == 'home' ? 'Home' : 'Work'} location cleared.');
        },
      );
    }
  }

  Future<void> _openPicker(String type) async {
    final picked = await Navigator.push<ll.LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          title: 'Set ${type.toUpperCase()}',
        ),
      ),
    );
    if (picked == null) return;

    _mapCubit.mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(picked.toLibre(), 15.0),
    );
    await _mapCubit.updateLayers();

    final error = type == 'home'
        ? await _mapCubit.saveHomeLocation(picked)
        : await _mapCubit.saveWorkLocation(picked);

    if (!mounted) return;
    if (error != null) {
      _showSnackBar('Failed to save to cloud: $error', color: Colors.redAccent);
      return;
    }
    _showSnackBar('${type == 'home' ? 'Home' : 'Work'} saved to cloud',
        color: Colors.green.shade700);
  }

  // ── Custom pins ────────────────────────────────────────────────────────────

  Future<void> _addCustomPin() async {
    final String? label = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Favorite Place'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "e.g. Grandma's House"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (label == null || label.isEmpty || !mounted) return;

    final result = await Navigator.push<ll.LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PickLocationScreen(title: 'Pick Favorite Location'),
      ),
    );

    if (result != null) {
      await _mapCubit.addCustomPin(label, result.toLibre());
      setState(() {});
    }
  }

  Future<void> _deleteCustomPin(Map<String, dynamic> pin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shortcut?'),
        content: Text('Do you want to remove "${pin['label']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _mapCubit.deleteCustomPin(pin);
      setState(() {});
    }
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileBottomSheet(
        userName: widget.userName,
        onProfileUpdate: () async {
          await _mapCubit.loadProfile();
          setState(() {});
        },
      ),
    );
  }

  void _showLayersMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLayerSelector(
        currentStyle: _mapCubit.state.currentStyle,
        isDark: isDark,
        showTraffic: _mapCubit.state.showTraffic,
        onStyleSelected: (style) {
          _mapCubit.setMapStyle(style);
          setState(() {});
        },
        onTrafficToggle: (value) {
          _mapCubit.toggleTraffic();
          setState(() {});
        },
      ),
    );
  }

  void _showRecentsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RecentsBottomSheet(
        history: _mapCubit.state.searchHistory,
        isDark: isDark,
        onSelect: (place) {
          Navigator.pop(context);
          _mapCubit.navigateTo(LatLng(place.lat, place.lon));
          setState(() {});
        },
        onClear: () async {
          await _mapCubit.loadHistory();
          if (!mounted) return;
          setState(() {});
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => _mapCubit,
      child: Scaffold(
        body: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            return Stack(
              children: [
                _buildMap(isDark, state),
                if (!state.isNavigating) _buildTopOverlay(isDark, state),
                _buildTopLayersButton(isDark, state),
                _buildNavigationGuidance(isDark, state),
                _buildBottomOverlay(isDark, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark, MapState state) {
    return RepaintBoundary(
      child: MapLibreMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
          zoom: AppConstants.defaultZoom,
        ),
        styleString: _mapCubit.getMapStyleString(isDark),
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        trackCameraPosition: true,
        myLocationEnabled: true,
        myLocationTrackingMode:
            (state.isNavigating || !_mapCubit.isFollowingUser)
                ? MyLocationTrackingMode.none
                : MyLocationTrackingMode.trackingCompass,
        myLocationRenderMode: MyLocationRenderMode.compass,
        compassEnabled: false,
        onCameraIdle: _onCameraIdle,
        onMapClick: _onMapClick,
      ),
    );
  }

  Widget _buildTopOverlay(bool isDark, MapState state) {
    return TopSearchOverlay(
      userName: widget.userName,
      greeting: _mapCubit.getTimeBasedGreeting(),
      isDark: isDark,
      isRouting: state.isRouting,
      showTopUI: !state.routeInfo.hasRoute,
      searchHistory: state.searchHistory,
      homeLocation: state.homeLocation,
      workLocation: state.workLocation,
      customPins: state.customPins,
      hasRecents: state.searchHistory.isNotEmpty,
      onSearchTap: _onWhereToTapped,
      onAvatarTap: _showProfileBottomSheet,
      onRecentsTap: _showRecentsBottomSheet,
      onHomeTap: () => _handleLocationButton('home'),
      onWorkTap: () => _handleLocationButton('work'),
      onCustomPinTap: (pin) {
        _mapCubit.navigateTo(ll.LatLng(pin['lat'], pin['lon']).toLibre());
        setState(() {});
      },
      onCustomPinLongPress: _deleteCustomPin,
      onAddTap: _addCustomPin,
    );
  }

  Widget _buildTopLayersButton(bool isDark, MapState state) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + context.h(240),
      right: context.w(20),
      child: MapControlsOverlay(
        isDark: isDark,
        isNavigating: state.isNavigating,
        is3dMode: state.is3dMode,
        hasRoute: state.routeInfo.hasRoute,
        bearing: state.bearing,
        onRelocate: _relocateMe,
        onLayers: _showLayersMenu,
        onTogglePerspective: _toggleMapPerspective,
        onResetBearing: () {
          if (_mapCubit.mapController != null) {
            _mapCubit.mapController!.animateCamera(CameraUpdate.bearingTo(0));
            _mapCubit.updateBearing(0.0);
          }
        },
        showLayersButton: false,
        showAtTop: true,
        showOnlyLayers: true,
      ),
    );
  }

  Widget _buildNavigationGuidance(bool isDark, MapState state) {
    if (!state.isNavigating) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + context.h(10),
      left: context.w(12),
      right: context.w(12),
      child: RepaintBoundary(
        child: NavigationGuidanceBar(
          routeInfo: state.routeInfo,
          currentStepIndex: _mapCubit.currentStepIndex,
          distanceToNextStep: state.distance,
          isDark: isDark,
          currentSpeed: state.currentSpeed,
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(bool isDark, MapState state) {
    return BottomMapControls(
      isDark: isDark,
      isNavigating: state.isNavigating,
      is3dMode: state.is3dMode,
      hasRoute: state.routeInfo.hasRoute,
      isFetchingRoute: state.isFetchingRoute,
      bearing: state.bearing,
      routeInfo: state.routeInfo,
      travelMode: state.travelMode,
      tripBar: TripBar(
        hasRoute: state.routeInfo.hasRoute,
        isNavigating: state.isNavigating,
        isDark: isDark,
        onTap: _onWhereToTapped,
        onStartNavigation: _toggleNavigation,
        onExitNavigation: _toggleNavigation,
      ),
      onRelocate: _relocateMe,
      onLayers: _showLayersMenu,
      onTogglePerspective: _toggleMapPerspective,
      onResetBearing: () {
        if (_mapCubit.mapController != null) {
          _mapCubit.mapController!.animateCamera(CameraUpdate.bearingTo(0));
          _mapCubit.updateBearing(0.0);
        }
      },
      onClearRoute: _clearRoute,
      onModeSelect: _setTravelMode,
      routeAlternatives: state.routeAlternatives,
      selectedAlternativeIndex: state.selectedAlternativeIndex,
      onShowAlternatives: _showRouteAlternatives,
      onShareLocation: _shareCurrentLocation,
    );
  }

  void _shareCurrentLocation() {
    final currentLocation = _mapCubit.state.currentLocation;
    if (currentLocation != null) {
      LocationShareService.shareLocation(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        placeName: 'My Current Location',
      );
    }
  }

  void _showRouteAlternatives() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteAlternativesSheet(
        alternatives: _mapCubit.state.routeAlternatives,
        selectedIndex: _mapCubit.state.selectedAlternativeIndex,
        isDark: isDark,
        onSelect: (index) {
          _mapCubit.selectRouteAlternative(index);
        },
      ),
    );
  }
}
