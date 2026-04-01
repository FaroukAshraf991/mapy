import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapy/core/utils/location_permission_helper.dart';
import 'package:mapy/features/map/screens/next_where_to_screen.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/utils/map_icon_helper.dart';
import 'package:mapy/features/map/widgets/route_alternatives_sheet.dart';
import 'package:mapy/blocs/map/map_cubit.dart';
class MapActionsHelper {
  final MapCubit mapCubit;
  final BuildContext context;
  final VoidCallback onStateChanged;
  final Function(String, {Color? color}) showSnackBar;
  final bool Function() isMounted;
  MapActionsHelper({
    required this.mapCubit,
    required this.context,
    required this.onStateChanged,
    required this.showSnackBar,
    required this.isMounted,
  });
  void onMapCreated(MapLibreMapController controller) {
    mapCubit.setMapController(controller);
    relocateMe();
  }
  Future<void> onStyleLoaded() async {
    await MapIconHelper.addStandardIcons(mapCubit.mapController!);
    await mapCubit.updateLayers(force: true);
  }
  void onCameraIdle() {
    if (isMounted() && mapCubit.mapController != null) {
      mapCubit.mapController!.getVisibleRegion();
      mapCubit.updateBearing(
          mapCubit.mapController!.cameraPosition?.bearing ?? 0.0);
    }
  }
  void onMapClick(dynamic point, LatLng latlng) {
    if (!mapCubit.state.isNavigating) {
      mapCubit.navigateTo(latlng);
      onStateChanged();
    }
  }
  Future<void> relocateMe() async {
    final result = await LocationPermissionHelper.requestPermission();
    if (!result.granted) {
      if (!isMounted()) return;
      showSnackBar(result.errorMessage ?? 'Location error');
      return;
    }
    try {
      final position = await mapCubit.getCurrentPosition();
      if (position == null || !isMounted()) return;
      onStateChanged();
      mapCubit.mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 18.0, tilt: 45),
        ),
        duration: const Duration(milliseconds: 1200),
      );
    } catch (e) {
      if (!isMounted()) return;
      showSnackBar('Location Error: $e');
    }
  }
  Future<void> onWhereToTapped() async {
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(builder: (_) => const NextWhereToScreen()),
    );
    if (picked == null || !isMounted()) return;
    await mapCubit.loadHistory();
    final loc = LatLng(picked.latitude, picked.longitude);
    await mapCubit.navigateTo(loc);
    onStateChanged();
  }
  Future<void> toggleNavigation() async {
    await mapCubit.toggleNavigation();
    if (mapCubit.state.isNavigating && mapCubit.state.currentLocation != null) {
      mapCubit.startLocationTracking();
    }
    onStateChanged();
  }
  void clearRoute() {
    mapCubit.clearRoute();
    onStateChanged();
  }
  void setTravelMode(TravelMode mode) {
    mapCubit.setTravelMode(mode);
  }
  void toggleMapPerspective() {
    mapCubit.toggleMapPerspective();
    onStateChanged();
  }
  Future<void> openPicker(String type) async {
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            PickLocationScreen(title: type == 'home' ? 'Home' : 'Work'),
      ),
    );
    if (picked == null || !isMounted()) return;
    final error = type == 'home'
        ? await mapCubit.saveHomeLocation(picked)
        : await mapCubit.saveWorkLocation(picked);
    if (!isMounted()) return;
    if (error != null) {
      showSnackBar('Failed to save $type location: $error',
          color: Colors.redAccent);
    } else {
      showSnackBar('${type == 'home' ? 'Home' : 'Work'} location saved!');
      onStateChanged();
    }
  }
  Future<void> addCustomPin() async {
    final nameController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New pin label'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Gym'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, nameController.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (label == null || label.trim().isEmpty) return;
    if (!isMounted()) return;
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(title: label.trim()),
      ),
    );
    if (picked == null) return;
    await mapCubit.addCustomPin(
        label.trim(), LatLng(picked.latitude, picked.longitude));
    if (!isMounted()) return;
    onStateChanged();
    showSnackBar('Pin "$label" saved!');
  }
  Future<void> deleteCustomPin(Map<String, dynamic> pin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pin?'),
        content: Text('Remove "${pin['label']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await mapCubit.deleteCustomPin(pin);
    if (!isMounted()) return;
    onStateChanged();
  }
  void shareCurrentLocation() {
    final currentLocation = mapCubit.state.currentLocation;
    if (currentLocation != null) {
      onStateChanged();
    }
  }
  void showRouteAlternatives() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteAlternativesSheet(
        alternatives: mapCubit.state.routeAlternatives,
        selectedIndex: mapCubit.state.selectedAlternativeIndex,
        isDark: isDark,
        onSelect: (index) {
          mapCubit.selectRouteAlternative(index);
          onStateChanged();
        },
      ),
    );
  }
}
