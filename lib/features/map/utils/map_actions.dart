import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:mapy/blocs/map/map_cubit.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/screens/next_where_to_screen.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/utils/map_layer_manager.dart';
import 'package:mapy/features/map/widgets/route_alternatives_sheet.dart';
import 'package:mapy/services/notification_service.dart';
import 'package:mapy/services/voice_navigation_service.dart';
import 'package:mapy/services/location_share_service.dart';

class MapActions {
  final MapCubit mapCubit;
  final BuildContext context;

  const MapActions({
    required this.mapCubit,
    required this.context,
  });

  Future<void> initialize() async {
    await mapCubit.initialize();
    NotificationService.initialize();
    await VoiceNavigationService.initialize();
    mapCubit.startLocationTracking();
  }

  void onMapCreated(MapLibreMapController controller) {
    mapCubit.setMapController(controller);
  }

  Future<void> onStyleLoaded() async {
    await mapCubit.updateLayers(force: true);
  }

  Future<void> relocateMe() async {
    try {
      final position = await mapCubit.getCurrentPosition();
      if (position != null) {
        mapCubit.mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 16.0,
              bearing: mapCubit.state.bearing,
            ),
          ),
          duration: const Duration(milliseconds: 1200),
        );
        mapCubit.updateCurrentLocation(position);
      }
    } catch (e) {
      debugPrint('Failed to relocate: $e');
    }
  }

  Future<void> onWhereToTapped() async {
    final result = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(builder: (_) => const NextWhereToScreen()),
    );
    if (result != null) {
      mapCubit.navigateTo(result.toLibre());
    }
  }

  Future<void> toggleNavigation() async {
    await mapCubit.toggleNavigation();
  }

  void clearRoute() {
    mapCubit.clearRoute();
  }

  void setTravelMode(TravelMode mode) {
    mapCubit.setTravelMode(mode);
  }

  void toggleMapPerspective() {
    mapCubit.toggleMapPerspective();
  }

  void handleLocationButton(String type) {
    final state = mapCubit.state;
    final location = type == 'home' ? state.homeLocation : state.workLocation;
    if (location != null) {
      mapCubit.navigateTo(location.toLibre());
    } else {
      openPicker(type);
    }
  }

  Future<void> openPicker(String type) async {
    final result = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            PickLocationScreen(title: type == 'home' ? 'Home' : 'Work'),
      ),
    );
    if (result != null) {
      if (type == 'home') {
        await mapCubit.saveHomeLocation(result);
      } else {
        await mapCubit.saveWorkLocation(result);
      }
    }
  }

  Future<void> addCustomPin() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Pin'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Enter a name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final position = await mapCubit.getCurrentPosition();
      if (position != null) {
        await mapCubit.addCustomPin(result, position);
      }
    }
  }

  Future<void> deleteCustomPin(Map<String, dynamic> pin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pin'),
        content: Text('Delete "${pin['label']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await mapCubit.deleteCustomPin(pin);
    }
  }

  void shareCurrentLocation() {
    final currentLocation = mapCubit.state.currentLocation;
    if (currentLocation != null) {
      LocationShareService.shareLocation(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        placeName: 'My Current Location',
      );
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
        },
      ),
    );
  }
}
