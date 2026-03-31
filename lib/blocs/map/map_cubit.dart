import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../core/constants/app_constants.dart';
import '../../services/geocoding_service.dart';
import '../../services/profile_service.dart';
import '../../services/search_history_service.dart';
import '../../services/notification_service.dart';
import '../../services/voice_navigation_service.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/models/route_info.dart';
import '../../features/map/utils/map_layer_manager.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(const MapState());

  MapLibreMapController? mapController;
  MapLayerManager? layerManager;

  double navigationRotation = 0.0;
  bool isFollowingUser = false;
  int currentStepIndex = 0;
  double distanceToNextStep = 0.0;

  DateTime? lastNotificationTime;
  String? lastNotificationText;
  int _routeRequestId = 0;

  StreamSubscription<Position>? positionSubscription;
  StreamSubscription<CompassEvent>? compassSubscription;

  String satelliteStyleJson = '''
  {
    "version": 8,
    "sources": {
      "satellite": {
        "type": "raster",
        "tiles": ["${AppConstants.satelliteTileUrl}"],
        "tileSize": 256,
        "attribution": "Esri, Maxar, Earthstar Geographics"
      }
    },
    "layers": [
      {
        "id": "satellite",
        "type": "raster",
        "source": "satellite",
        "minzoom": 0,
        "maxzoom": 20
      }
    ]
  }
  ''';

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
    final style =
        savedStyle == 'satellite' ? MapStyle.satellite : MapStyle.street;
    emit(state.copyWith(currentStyle: style));
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final uid = Supabase.instance.client.auth.currentUser?.id;

    double? homeLat;
    double? homeLon;
    double? workLat;
    double? workLon;

    if (uid != null) {
      homeLat = prefs.getDouble('home_lat_$uid');
      homeLon = prefs.getDouble('home_lon_$uid');
      workLat = prefs.getDouble('work_lat_$uid');
      workLon = prefs.getDouble('work_lon_$uid');
    }

    if (homeLat == null || homeLon == null) {
      homeLat = prefs.getDouble('home_lat');
      homeLon = prefs.getDouble('home_lon');
    }
    if (workLat == null || workLon == null) {
      workLat = prefs.getDouble('work_lat');
      workLon = prefs.getDouble('work_lon');
    }

    final customPinsJson =
        prefs.getStringList('custom_pins${uid != null ? '_$uid' : ''}');

    ll.LatLng? home;
    ll.LatLng? work;
    List<Map<String, dynamic>> pins = [];

    if (homeLat != null && homeLon != null) {
      home = ll.LatLng(homeLat, homeLon);
    }
    if (workLat != null && workLon != null) {
      work = ll.LatLng(workLat, workLon);
    }
    if (customPinsJson != null && customPinsJson.isNotEmpty) {
      pins = customPinsJson
          .map((s) {
            try {
              return Map<String, dynamic>.from(
                  json.decode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    try {
      final profile = await ProfileService.loadProfile();
      if (profile.home != null) {
        home = profile.home;
        await prefs.setDouble('home_lat_$uid', profile.home!.latitude);
        await prefs.setDouble('home_lon_$uid', profile.home!.longitude);
      }
      if (profile.work != null) {
        work = profile.work;
        await prefs.setDouble('work_lat_$uid', profile.work!.latitude);
        await prefs.setDouble('work_lon_$uid', profile.work!.longitude);
      }
      if (profile.customPins.isNotEmpty) {
        pins = profile.customPins;
        await prefs.setStringList(
          'custom_pins_$uid',
          pins.map((p) => json.encode(p)).toList(),
        );
      }
    } catch (_) {}

    emit(state.copyWith(
      homeLocation: home,
      workLocation: work,
      customPins: pins,
    ));
  }

  Future<void> loadHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final history = await SearchHistoryService.getHistory(uid);
    emit(state.copyWith(searchHistory: history));
  }

  void setMapStyle(MapStyle style) {
    emit(state.copyWith(currentStyle: style));
  }

  String getMapStyleString(bool isDark) {
    switch (state.currentStyle) {
      case MapStyle.satellite:
        return satelliteStyleJson;
      case MapStyle.street:
        return isDark ? AppConstants.darkStyleUrl : AppConstants.osmStyleUrl;
    }
  }

  void updateCurrentLocation(LatLng loc) {
    emit(state.copyWith(currentLocation: loc));
  }

  void updateBearing(double bearing) {
    emit(state.copyWith(bearing: bearing));
  }

  Future<void> navigateTo(LatLng loc) async {
    if (state.currentLocation == null) return;

    final int requestId = ++_routeRequestId;
    emit(state.copyWith(isFetchingRoute: true, isRouting: true));

    try {
      final alternatives = await GeocodingService.getRouteAlternatives(
        state.currentLocation!.toLl2(),
        loc.toLl2(),
        mode: state.travelMode,
      );

      if (requestId != _routeRequestId) return;

      if (alternatives.isNotEmpty) {
        emit(state.copyWith(
          destinationLocation: loc,
          routeInfo: alternatives.first.routeInfo,
          routeAlternatives: alternatives,
          selectedAlternativeIndex: 0,
          isRouting: false,
          isFetchingRoute: false,
        ));
      } else {
        emit(state.copyWith(
          destinationLocation: loc,
          routeInfo: RouteInfo.empty,
          routeAlternatives: [],
          isRouting: false,
          isFetchingRoute: false,
        ));
      }

      currentStepIndex = 0;
      distanceToNextStep = 0.0;

      if (alternatives.isNotEmpty && alternatives.first.routeInfo.hasRoute) {
        final mlBounds = LatLngBounds(
          southwest: ll.LatLng(
            math.min(state.currentLocation!.latitude, loc.latitude),
            math.min(state.currentLocation!.longitude, loc.longitude),
          ).toLibre(),
          northeast: ll.LatLng(
            math.max(state.currentLocation!.latitude, loc.latitude),
            math.max(state.currentLocation!.longitude, loc.longitude),
          ).toLibre(),
        );
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(mlBounds,
              left: 80, top: 80, right: 80, bottom: 80),
        );
      } else {
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.0));
      }
      await updateLayers(force: true);
    } catch (_) {
      if (requestId != _routeRequestId) return;
      emit(state.copyWith(isRouting: false, isFetchingRoute: false));
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.0));
    }
  }

  void selectRouteAlternative(int index) {
    if (index < 0 || index >= state.routeAlternatives.length) return;
    final alternative = state.routeAlternatives[index];
    emit(state.copyWith(
      routeInfo: alternative.routeInfo,
      selectedAlternativeIndex: index,
    ));
    currentStepIndex = 0;
    distanceToNextStep = 0.0;
    updateLayers(force: true);
  }

  void setTravelMode(TravelMode mode) {
    if (state.travelMode == mode) return;
    emit(state.copyWith(travelMode: mode));

    if (state.destinationLocation != null) {
      navigateTo(state.destinationLocation!);
    }
  }

  void toggleTraffic() {
    final newShowTraffic = !state.showTraffic;
    emit(state.copyWith(showTraffic: newShowTraffic));
    updateLayers(force: true);
  }

  Future<void> toggleNavigation() async {
    if (mapController == null) return;

    if (!state.isNavigating && state.currentLocation == null) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        emit(state.copyWith(
            currentLocation: LatLng(pos.latitude, pos.longitude)));
      } catch (_) {}
    }

    final newIsNavigating = !state.isNavigating;
    isFollowingUser = newIsNavigating;

    if (!newIsNavigating) {
      navigationRotation = 0.0;
      mapController!.animateCamera(CameraUpdate.bearingTo(0));
      mapController!.animateCamera(CameraUpdate.tiltTo(0));
      NotificationService.cancelNavigationNotification();
    }

    emit(state.copyWith(isNavigating: newIsNavigating));

    if (newIsNavigating && state.currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: state.currentLocation!,
            zoom: 17.5,
            tilt: 65,
            bearing: navigationRotation,
          ),
        ),
        duration: const Duration(milliseconds: 2000),
      );
    }
    await updateLayers(force: true);
  }

  void toggleMapPerspective() {
    final newIs3dMode = !state.is3dMode;
    emit(state.copyWith(is3dMode: newIs3dMode));
    mapController?.animateCamera(
      CameraUpdate.tiltTo(newIs3dMode ? 60 : 0),
    );
  }

  void clearRoute() {
    if (state.isNavigating) {
      toggleNavigation();
    }
    emit(state.copyWith(
      destinationLocation: null,
      routeInfo: RouteInfo.empty,
      isNavigating: false,
      isRouting: false,
    ));
    currentStepIndex = 0;
    distanceToNextStep = 0.0;
    NotificationService.cancelNavigationNotification();
    updateLayers();
  }

  Future<void> updateLayers({bool force = false}) async {
    if (layerManager == null) return;

    await layerManager!.updateLayers(
      routeInfo: state.routeInfo,
      destinationLocation: state.destinationLocation,
      currentLocation: state.currentLocation,
      homeLocation: state.homeLocation,
      workLocation: state.workLocation,
      customPins: state.customPins,
      isNavigating: state.isNavigating,
      navigationRotation: navigationRotation,
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
      final newLoc = LatLng(position.latitude, position.longitude);
      final speedKmH = position.speed * 3.6;
      emit(state.copyWith(currentLocation: newLoc, currentSpeed: speedKmH));

      if (state.isNavigating && isFollowingUser) {
        _updateNavigationPerspective(position);
        _updateGuidance(position);
      }
    });

    compassSubscription?.cancel();
    compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (state.isNavigating && event.heading != null) {
        // Ignore magnetic compass if driving/riding and moving fast (GPS track angle is better for roads)
        bool isVehicle = state.travelMode == TravelMode.driving || state.travelMode == TravelMode.motorcycle;
        if (isVehicle && state.currentSpeed > 4.0) return;

        double newHeading = event.heading!;
        double diff = (navigationRotation - newHeading).abs();
        if (diff > 180) diff = 360 - diff;
        if (diff > 1.5) {
          navigationRotation = newHeading;
          if (isFollowingUser) {
            _updateCameraFromCurrentState();
          }
          updateLayers();
        }
      }
    });
  }

  void _updateNavigationPerspective(Position position) {
    if (mapController == null || state.currentLocation == null) return;
    
    // GPS track angle exactly binds to the road/movement path!
    // We use it if driving a vehicle over ~4km/h, or if compass wasn't ready.
    bool isVehicle = state.travelMode == TravelMode.driving || state.travelMode == TravelMode.motorcycle;
    if ((isVehicle && state.currentSpeed > 4.0) || navigationRotation == 0.0) {
      if (position.heading >= 0.0) {
        navigationRotation = position.heading;
      }
    }
    
    _updateCameraFromCurrentState();
    updateLayers();
  }

  void _updateCameraFromCurrentState() {
    if (mapController == null || state.currentLocation == null) return;

    final speedKmH = state.currentSpeed;
    final targetZoom = AppConstants.baseZoom -
        (speedKmH / AppConstants.speedToZoomDivisor)
            .clamp(0, AppConstants.maxZoomReduction);
    final targetTilt = AppConstants.baseTilt +
        (speedKmH / AppConstants.speedToTiltDivisor)
            .clamp(0, AppConstants.maxTiltIncrease);

    final bearingRad = navigationRotation * math.pi / 180;
    final latOffset =
        AppConstants.cameraOffsetDistance * (math.cos(bearingRad));
    final lngOffset =
        AppConstants.cameraOffsetDistance * (math.sin(bearingRad));

    final offsetCenter = LatLng(
      state.currentLocation!.latitude + latOffset,
      state.currentLocation!.longitude + lngOffset,
    );

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: offsetCenter,
          zoom: targetZoom,
          tilt: targetTilt,
          bearing: navigationRotation,
        ),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  void _updateGuidance(Position position) {
    if (state.routeInfo.steps.isEmpty ||
        currentStepIndex >= state.routeInfo.steps.length) {
      return;
    }

    final currentStep = state.routeInfo.steps[currentStepIndex];

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.location.latitude,
      currentStep.location.longitude,
    );

    emit(state.copyWith(distance: distance));
    distanceToNextStep = distance;

    final distanceText = distanceToNextStep > 1000
        ? '${(distanceToNextStep / 1000).toStringAsFixed(1)} km'
        : '${distanceToNextStep.round()} m';

    if (distance < AppConstants.stepAdvanceDistanceMeters &&
        currentStepIndex < state.routeInfo.steps.length - 1) {
      currentStepIndex++;
      VoiceNavigationService.speakTurnInstruction(
        state.routeInfo.steps[currentStepIndex].instruction,
        distanceText,
      );
    }

    final now = DateTime.now();
    final updateKey = '${currentStep.instruction}-$distanceText';
    if (lastNotificationTime == null ||
        now.difference(lastNotificationTime!).inMilliseconds >
            AppConstants.notificationThrottleMs ||
        lastNotificationText != updateKey) {
      lastNotificationTime = now;
      lastNotificationText = updateKey;
      NotificationService.showNavigationNotification(
        instruction: currentStep.instruction,
        distance: distanceText,
      );
      VoiceNavigationService.speakTurnInstruction(
          currentStep.instruction, distanceText);
    }
  }

  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<LatLng?> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<String?> saveHomeLocation(ll.LatLng location) async {
    emit(state.copyWith(homeLocation: location));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_lat', location.latitude);
    await prefs.setDouble('home_lon', location.longitude);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setDouble('home_lat_$uid', location.latitude);
      await prefs.setDouble('home_lon_$uid', location.longitude);
    }
    return await ProfileService.saveHomeLocation(location);
  }

  Future<String?> saveWorkLocation(ll.LatLng location) async {
    emit(state.copyWith(workLocation: location));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('work_lat', location.latitude);
    await prefs.setDouble('work_lon', location.longitude);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setDouble('work_lat_$uid', location.latitude);
      await prefs.setDouble('work_lon_$uid', location.longitude);
    }
    return await ProfileService.saveWorkLocation(location);
  }

  Future<String?> clearHomeLocation() async {
    emit(state.copyWith(homeLocation: null));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('home_lat');
    await prefs.remove('home_lon');
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.remove('home_lat_$uid');
      await prefs.remove('home_lon_$uid');
    }
    return await ProfileService.clearHomeLocation();
  }

  Future<String?> clearWorkLocation() async {
    emit(state.copyWith(workLocation: null));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('work_lat');
    await prefs.remove('work_lon');
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.remove('work_lat_$uid');
      await prefs.remove('work_lon_$uid');
    }
    return await ProfileService.clearWorkLocation();
  }

  Future<void> addCustomPin(String label, LatLng location) async {
    final newPin = {
      'label': label,
      'lat': location.latitude,
      'lon': location.longitude,
    };
    final pins = [...state.customPins, newPin];
    emit(state.copyWith(customPins: pins));

    final prefs = await SharedPreferences.getInstance();
    final pinsJson = pins.map((p) => json.encode(p)).toList();

    await prefs.setStringList('custom_pins', pinsJson);

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setStringList('custom_pins_$uid', pinsJson);
    }
    await ProfileService.saveCustomPins(pins);
  }

  Future<void> deleteCustomPin(Map<String, dynamic> pin) async {
    final pins = [...state.customPins];
    pins.remove(pin);
    emit(state.copyWith(customPins: pins));

    final prefs = await SharedPreferences.getInstance();
    final pinsJson = pins.map((p) => json.encode(p)).toList();

    await prefs.setStringList('custom_pins', pinsJson);

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await prefs.setStringList('custom_pins_$uid', pinsJson);
    }
    await ProfileService.saveCustomPins(pins);
  }

  @override
  Future<void> close() {
    positionSubscription?.cancel();
    compassSubscription?.cancel();
    return super.close();
  }
}
