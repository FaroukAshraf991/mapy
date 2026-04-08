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
      mapCubit.onCameraIdleDragCheck();
    }
  }

  void onMapClick(dynamic point, LatLng latlng) {
    if (!mapCubit.state.isNavigating) {
      debugPrint('🔄 Map tapped - setting destination name to Dropped pin');
      mapCubit.setOriginName('Your location');
      mapCubit.setStartName('Your location');
      mapCubit.setDestinationName('Dropped pin');

      // Set start location to current GPS location
      final currentLoc = mapCubit.state.currentLocation;
      if (currentLoc != null) {
        mapCubit.emit(mapCubit.state.copyWith(startLocation: currentLoc));
      }

      debugPrint('🔄 Navigating to tapped location...');
      mapCubit.navigateTo(latlng);
      debugPrint('🔄 Calling onStateChanged...');
      onStateChanged();
      debugPrint('🔄 onMapClick done');
    }
  }

  Future<void> relocateMe() async {
    final result = await LocationPermissionHelper.requestPermission();
    if (!result.granted) {
      if (!isMounted()) return;
      showSnackBar(result.errorMessage ?? 'Location error');
      return;
    }
    await mapCubit.cycleFollowMode();
    if (isMounted()) onStateChanged();
  }

  Future<void> onWhereToTapped() async {
    final state = mapCubit.state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => NextWhereToScreen(
          homeLocation: state.homeLocation,
          workLocation: state.workLocation,
          customPins: state.customPins,
          searchHistory: state.searchHistory,
        ),
      ),
    );
    if (result == null || !isMounted()) return;
    await _applySearchResult(result);
  }

  Future<void> onWhereToTappedWithQuery(String query) async {
    final state = mapCubit.state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => NextWhereToScreen(
          homeLocation: state.homeLocation,
          workLocation: state.workLocation,
          customPins: state.customPins,
          searchHistory: state.searchHistory,
          initialQuery: query,
        ),
      ),
    );
    if (result == null || !isMounted()) return;
    await _applySearchResult(result);
  }

  Future<void> onChangeOriginTapped() async {
    final state = mapCubit.state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => NextWhereToScreen(
          homeLocation: state.homeLocation,
          workLocation: state.workLocation,
          customPins: state.customPins,
          searchHistory: state.searchHistory,
        ),
      ),
    );
    if (result == null || !isMounted()) return;
    // Only handle plain place selection — ignore setHome/setWork/addPin here
    final action = result['action'] as String?;
    if (action != null) return;

    final lat = result['lat'] as double;
    final lon = result['lon'] as double;
    final name = result['name'] as String? ?? 'Custom location';

    mapCubit.emit(
        mapCubit.state.copyWith(startLocation: LatLng(lat, lon)));
    mapCubit.setOriginName(name);
    mapCubit.setStartName(name);

    final dest = mapCubit.state.destinationLocation;
    if (dest != null) await mapCubit.navigateTo(dest);
    if (isMounted()) onStateChanged();
  }

  Future<void> onCategoryTapped(String query) async {
    final state = mapCubit.state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => NextWhereToScreen(
          initialQuery: query,
          homeLocation: state.homeLocation,
          workLocation: state.workLocation,
          customPins: state.customPins,
          searchHistory: state.searchHistory,
        ),
      ),
    );
    if (result == null || !isMounted()) return;
    await _applySearchResult(result);
  }

  Future<void> _applySearchResult(Map<String, dynamic> result) async {
    final action = result['action'] as String?;
    final lat = result['lat'] as double;
    final lon = result['lon'] as double;
    final loc = LatLng(lat, lon);
    final llLoc = ll.LatLng(lat, lon);

    if (action == 'setHome') {
      await mapCubit.saveHomeLocation(llLoc);
      if (isMounted()) showSnackBar('Home location saved');
      return;
    }
    if (action == 'setWork') {
      await mapCubit.saveWorkLocation(llLoc);
      if (isMounted()) showSnackBar('Work location saved');
      return;
    }
    if (action == 'addPin') {
      final label = result['name'] as String;
      await mapCubit.addCustomPin(label, loc);
      if (isMounted()) showSnackBar('Pin "$label" saved!');
      return;
    }

    await mapCubit.loadHistory();

    final currentLoc = mapCubit.state.currentLocation;
    if (currentLoc != null) {
      mapCubit.emit(mapCubit.state.copyWith(startLocation: currentLoc));
    }

    mapCubit.setOriginName('Your location');
    mapCubit.setStartName('Your location');
    mapCubit.setDestinationName(result['name'] as String?);

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

  void swapEndpoints() {
    debugPrint('🔄 swapEndpoints called!');
    mapCubit.swapRoute();
    onStateChanged();
    debugPrint('🔄 swapEndpoints done!');
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
