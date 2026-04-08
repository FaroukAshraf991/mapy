import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../core/constants/app_constants.dart';
import '../../services/search_history_service.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/utils/map_layer_manager.dart';
import 'map_navigation_mixin.dart';
import 'map_profile_helper.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> with MapCubitNavigationMixin {
  MapCubit() : super(const MapState());

  @override
  MapLibreMapController? mapController;
  MapLayerManager? layerManager;

  @override
  double navigationRotation = 0.0;

  @override
  bool isFollowingUser = false;

  @override
  int currentStepIndex = 0;

  @override
  double distanceToNextStep = 0.0;

  @override
  int routeProgressIndex = 0;

  DateTime? lastNotificationTime;
  String? lastNotificationText;
  DateTime? _lastFollowAnimateTime;

  StreamSubscription<Position>? positionSubscription;
  StreamSubscription<CompassEvent>? compassSubscription;

  String get satelliteStyleJson =>
      '{"version":8,"sources":{"satellite":{"type":"raster","tiles":["${AppConstants.satelliteTileUrl}"],"tileSize":256,"attribution":"Esri, Maxar, Earthstar Geographics"}},"layers":[{"id":"satellite","type":"raster","source":"satellite","minzoom":0,"maxzoom":20}]}';

  Future<void> initialize() async {
    await loadSettings();
    await loadProfile();
    await loadHistory();
  }

  void setMapController(MapLibreMapController controller) {
    mapController = controller;
    layerManager = MapLayerManager(controller);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStyle = prefs.getString('default_map_style') ?? 'street';
    emit(state.copyWith(
        currentStyle:
            savedStyle == 'satellite' ? MapStyle.satellite : MapStyle.street));
  }

  Future<void> loadProfile() async =>
      await MapProfileHelper.loadProfile(emit: emit, currentState: state);

  Future<void> loadHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    emit(state.copyWith(
        searchHistory: await SearchHistoryService.getHistory(uid)));
  }

  void setMapStyle(MapStyle style) => emit(state.copyWith(currentStyle: style));

  String getMapStyleString(bool isDark) {
    switch (state.currentStyle) {
      case MapStyle.satellite:
        return satelliteStyleJson;
      case MapStyle.street:
        return isDark ? AppConstants.darkStyleUrl : AppConstants.osmStyleUrl;
      case MapStyle.terrain:
        return isDark ? AppConstants.darkStyleUrl : AppConstants.osmStyleUrl;
    }
  }

  /// Cycles follow mode: none → follow → compass → follow → …
  /// Called by the locate-me button tap.
  Future<void> cycleFollowMode() async {
    // First tap when location unknown: acquire it, then enter follow
    if (state.currentLocation == null) {
      try {
        final pos = await getCurrentPosition();
        if (pos == null || isClosed) return;
        updateCurrentLocation(pos);
      } catch (_) {
        return;
      }
    }

    final next = switch (state.locationFollowMode) {
      LocationFollowMode.none => LocationFollowMode.follow,
      LocationFollowMode.follow => LocationFollowMode.compass,
      LocationFollowMode.compass => LocationFollowMode.follow,
    };

    emit(state.copyWith(locationFollowMode: next));
    _animateToUserInFollowMode(next);
  }

  void breakFollowMode() {
    if (state.locationFollowMode != LocationFollowMode.none && !state.isNavigating) {
      emit(state.copyWith(locationFollowMode: LocationFollowMode.none));
    }
  }

  /// Called from onCameraIdle to detect user-initiated map drags.
  void onCameraIdleDragCheck() {
    if (state.locationFollowMode == LocationFollowMode.none || state.isNavigating) return;
    final now = DateTime.now();
    // If we haven't programmatically moved the camera in the last 900ms, the user dragged.
    if (_lastFollowAnimateTime == null ||
        now.difference(_lastFollowAnimateTime!).inMilliseconds > 900) {
      breakFollowMode();
    }
  }

  void _animateToUserInFollowMode(LocationFollowMode mode) {
    if (mapController == null || state.currentLocation == null) return;
    _lastFollowAnimateTime = DateTime.now();

    if (mode == LocationFollowMode.compass) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.currentLocation!,
            zoom: 17.0,
            tilt: 50.0,
            bearing: navigationRotation,
          ),
        ),
        duration: const Duration(milliseconds: 700),
      );
    } else {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.currentLocation!,
            zoom: 16.0,
            tilt: 0.0,
            bearing: 0.0,
          ),
        ),
        duration: const Duration(milliseconds: 700),
      );
    }
  }

  void _updateFollowCamera() {
    if (mapController == null || state.currentLocation == null) return;
    if (state.locationFollowMode == LocationFollowMode.none) return;
    _lastFollowAnimateTime = DateTime.now();

    final currentZoom = mapController!.cameraPosition?.zoom;

    if (state.locationFollowMode == LocationFollowMode.compass) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.currentLocation!,
            zoom: currentZoom ?? 17.0,
            tilt: 50.0,
            bearing: navigationRotation,
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
    } else {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.currentLocation!,
            zoom: currentZoom ?? 16.0,
            tilt: 0.0,
            bearing: 0.0,
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void toggleTransit() {
    emit(state.copyWith(showTransit: !state.showTransit));
    updateLayers(force: true);
  }

  void toggleBiking() {
    emit(state.copyWith(showBiking: !state.showBiking));
    updateLayers(force: true);
  }

  void updateCurrentLocation(LatLng loc) =>
      emit(state.copyWith(currentLocation: loc));
  void updateBearing(double bearing) => emit(state.copyWith(bearing: bearing));
  void setDestinationName(String? name) =>
      emit(state.copyWith(destinationName: name));
  void setOriginName(String? name) => emit(state.copyWith(originName: name));

  void setStartName(String? name) => emit(state.copyWith(startName: name));

  void swapRoute() {
    final tempDest = state.destinationLocation;
    final tempDestName = state.destinationName;
    final tempStart = state.startLocation;
    final tempOriginName = state.originName;
    final currentRoute = state.routeInfo;

    if (!currentRoute.hasRoute) return;

    // Reverse the route points
    final reversedRoute = currentRoute.reversed;

    // Update state with reversed route and swapped locations/names
    // Swap originName with destinationName
    emit(state.copyWith(
      routeInfo: reversedRoute,
      destinationLocation: tempStart,
      destinationName: tempOriginName ?? 'Your location',
      originName: tempDestName ?? 'Dropped pin',
      startLocation: tempDest,
      startName: tempDestName ?? 'Dropped pin',
      isRouteSwapped: !state.isRouteSwapped,
    ));

    // Update layers to show reversed route
    updateLayers(force: true);
  }

  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
  }

  Future<LatLng?> getCurrentPosition() async {
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<String?> saveHomeLocation(ll.LatLng location) async {
    emit(state.copyWith(homeLocation: location));
    return await MapProfileHelper.saveHomeLocation(location);
  }

  Future<String?> saveWorkLocation(ll.LatLng location) async {
    emit(state.copyWith(workLocation: location));
    return await MapProfileHelper.saveWorkLocation(location);
  }

  Future<String?> clearHomeLocation() async {
    emit(state.copyWith(homeLocation: null));
    return await MapProfileHelper.clearHomeLocation();
  }

  Future<String?> clearWorkLocation() async {
    emit(state.copyWith(workLocation: null));
    return await MapProfileHelper.clearWorkLocation();
  }

  Future<void> addCustomPin(String label, LatLng location) async {
    final pins = [
      ...state.customPins,
      {'label': label, 'lat': location.latitude, 'lon': location.longitude}
    ];
    emit(state.copyWith(customPins: pins));
    await MapProfileHelper.saveCustomPins(pins);
  }

  Future<void> deleteCustomPin(Map<String, dynamic> pin) async {
    final pins = [...state.customPins]..remove(pin);
    emit(state.copyWith(customPins: pins));
    await MapProfileHelper.saveCustomPins(pins);
  }

  @override
  Future<void> updateLayers({bool force = false}) async {
    if (layerManager == null) return;
    await layerManager!.updateLayers(
      routeInfo: state.routeInfo,
      destinationLocation: state.destinationLocation,
      currentLocation: state.currentLocation,
      startLocation: state.startLocation,
      homeLocation: state.homeLocation,
      workLocation: state.workLocation,
      customPins: state.customPins,
      isNavigating: state.isNavigating,
      navigationRotation: navigationRotation,
      routeProgressIndex: routeProgressIndex,
      force: force,
      showTraffic: state.showTraffic,
    );
  }

  void startLocationTracking() {
    positionSubscription?.cancel();
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: state.isNavigating
            ? LocationAccuracy.bestForNavigation
            : LocationAccuracy.medium,
        distanceFilter: state.isNavigating ? 2 : 5,
      ),
    ).listen((Position position) {
      if (isClosed) return;
      emit(state.copyWith(
        currentLocation: LatLng(position.latitude, position.longitude),
        currentSpeed: position.speed * 3.6,
      ));
      if (state.isNavigating && isFollowingUser) {
        updateGuidance(position);
        updateNavigationPerspective(position);
      } else {
        updateLayers();
        if (state.locationFollowMode != LocationFollowMode.none) {
          _updateFollowCamera();
        }
      }
    });
    compassSubscription?.cancel();
    compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (isClosed) return;
      if (event.heading == null) return;

      if (state.isNavigating) {
        if ((state.travelMode == TravelMode.driving ||
                state.travelMode == TravelMode.motorcycle) &&
            state.currentSpeed > 4.0) return;
        final diff =
            ((navigationRotation - event.heading!).abs() + 180) % 360 - 180;
        if (diff.abs() > 1.5) {
          navigationRotation = event.heading!;
          if (isFollowingUser) updateCameraFromCurrentState();
          updateLayers();
        }
      } else if (state.locationFollowMode == LocationFollowMode.compass) {
        final diff =
            ((navigationRotation - event.heading!).abs() + 180) % 360 - 180;
        if (diff.abs() > 1.5) {
          navigationRotation = event.heading!;
          _updateFollowCamera();
        }
      }
    });
  }

  @override
  Future<void> close() {
    positionSubscription?.cancel();
    compassSubscription?.cancel();
    return super.close();
  }
}
