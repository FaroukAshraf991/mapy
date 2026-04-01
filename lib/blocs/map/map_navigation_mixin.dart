import 'dart:async';
import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/models/route_info.dart';
import '../../services/notification_service.dart';
import '../../services/voice_navigation_service.dart';
import '../../core/constants/app_constants.dart';
import 'map_state.dart';

mixin MapCubitNavigationMixin {
  MapState get state;
  MapLibreMapController? get mapController;
  double get navigationRotation;
  set navigationRotation(double value);
  bool get isFollowingUser;
  set isFollowingUser(bool value);
  int get currentStepIndex;
  set currentStepIndex(int value);
  double get distanceToNextStep;
  set distanceToNextStep(double value);
  Future<void> updateLayers({bool force});
  void emit(MapState state);

  Future<void> navigateTo(LatLng loc) async {
    if (state.currentLocation == null || mapController == null) return;
    emit(state.copyWith(destinationLocation: loc, isRouting: true));
    await updateLayers(force: true);
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(state.currentLocation!.latitude, loc.latitude),
        math.min(state.currentLocation!.longitude, loc.longitude),
      ),
      northeast: LatLng(
        math.max(state.currentLocation!.latitude, loc.latitude),
        math.max(state.currentLocation!.longitude, loc.longitude),
      ),
    );
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds,
          left: 80, top: 80, right: 80, bottom: 80),
    );
    emit(state.copyWith(isRouting: false));
  }

  void selectRouteAlternative(int index) {
    if (index < 0 || index >= state.routeAlternatives.length) return;
    final alternative = state.routeAlternatives[index];
    emit(state.copyWith(
        routeInfo: alternative.routeInfo, selectedAlternativeIndex: index));
    currentStepIndex = 0;
    distanceToNextStep = 0.0;
    updateLayers(force: true);
  }

  void setTravelMode(TravelMode mode) {
    if (state.travelMode == mode) return;
    emit(state.copyWith(travelMode: mode));
    if (state.destinationLocation != null)
      navigateTo(state.destinationLocation!);
  }

  void toggleTraffic() {
    emit(state.copyWith(showTraffic: !state.showTraffic));
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
              bearing: navigationRotation),
        ),
        duration: const Duration(milliseconds: 2000),
      );
    }
    await updateLayers(force: true);
  }

  void toggleMapPerspective() {
    final newIs3dMode = !state.is3dMode;
    emit(state.copyWith(is3dMode: newIs3dMode));
    mapController?.animateCamera(CameraUpdate.tiltTo(newIs3dMode ? 60 : 0));
  }

  void clearRoute() {
    if (state.isNavigating) toggleNavigation();
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

  void updateNavigationPerspective(Position position) {
    if (mapController == null || state.currentLocation == null) return;
    bool isVehicle = state.travelMode == TravelMode.driving ||
        state.travelMode == TravelMode.motorcycle;
    if ((isVehicle && state.currentSpeed > 4.0) || navigationRotation == 0.0) {
      if (position.heading >= 0.0) navigationRotation = position.heading;
    }
    updateCameraFromCurrentState();
    updateLayers();
  }

  void updateCameraFromCurrentState() {
    if (mapController == null || state.currentLocation == null) return;
    final speedKmH = state.currentSpeed;
    final targetZoom = AppConstants.baseZoom -
        (speedKmH / AppConstants.speedToZoomDivisor)
            .clamp(0, AppConstants.maxZoomReduction);
    final targetTilt = AppConstants.baseTilt +
        (speedKmH / AppConstants.speedToTiltDivisor)
            .clamp(0, AppConstants.maxTiltIncrease);
    final bearingRad = navigationRotation * math.pi / 180;
    final latOffset = AppConstants.cameraOffsetDistance * math.cos(bearingRad);
    final lngOffset = AppConstants.cameraOffsetDistance * math.sin(bearingRad);
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
            bearing: navigationRotation),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  void updateGuidance(Position position) {
    if (state.routeInfo.steps.isEmpty ||
        currentStepIndex >= state.routeInfo.steps.length) return;
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
  }
}
