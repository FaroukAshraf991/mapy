import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../core/constants/app_constants.dart';
import '../../services/geocoding_service.dart';
import '../../services/notification_service.dart';
import '../../services/voice_navigation_service.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/models/route_info.dart';
import '../../features/map/utils/map_layer_manager.dart';
import 'map_state.dart';
class MapNavigationHelper {
  static Future<void> navigateTo(
      {required LatLng destination,
      required MapState currentState,
      required void Function(MapState) onStateChange,
      required int routeRequestId,
      required MapLibreMapController? mapController,
      required int currentStepIndex,
      required void Function(int) onStepIndexChange,
      required double distanceToNextStep,
      required void Function(double) onDistanceChange,
      required Future<void> Function({bool force}) updateLayers}) async {
    if (currentState.currentLocation == null) return;
    onStateChange(
        currentState.copyWith(isFetchingRoute: true, isRouting: true));
    try {
      final alternatives = await GeocodingService.getRouteAlternatives(
          currentState.currentLocation!.toLl2(), destination.toLl2(),
          mode: currentState.travelMode);
      if (alternatives.isNotEmpty) {
        onStateChange(currentState.copyWith(
            destinationLocation: destination,
            routeInfo: alternatives.first.routeInfo,
            routeAlternatives: alternatives,
            selectedAlternativeIndex: 0,
            isRouting: false,
            isFetchingRoute: false));
      } else {
        onStateChange(currentState.copyWith(
            destinationLocation: destination,
            routeInfo: RouteInfo.empty,
            routeAlternatives: [],
            isRouting: false,
            isFetchingRoute: false));
      }
      onStepIndexChange(0);
      onDistanceChange(0.0);
      if (alternatives.isNotEmpty && alternatives.first.routeInfo.hasRoute) {
        final mlBounds = LatLngBounds(
          southwest: ll.LatLng(
                  math.min(currentState.currentLocation!.latitude,
                      destination.latitude),
                  math.min(currentState.currentLocation!.longitude,
                      destination.longitude))
              .toLibre(),
          northeast: ll.LatLng(
                  math.max(currentState.currentLocation!.latitude,
                      destination.latitude),
                  math.max(currentState.currentLocation!.longitude,
                      destination.longitude))
              .toLibre(),
        );
        mapController?.animateCamera(CameraUpdate.newLatLngBounds(mlBounds,
            left: 80, top: 80, right: 80, bottom: 80));
      } else {
        mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(destination, 15.0));
      }
      await updateLayers(force: true);
    } catch (_) {
      onStateChange(
          currentState.copyWith(isRouting: false, isFetchingRoute: false));
      mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(destination, 15.0));
    }
  }
  static void selectRouteAlternative(
      {required int index,
      required MapState currentState,
      required void Function(MapState) onStateChange,
      required void Function(int) onStepIndexChange,
      required void Function(double) onDistanceChange,
      required Future<void> Function({bool force}) updateLayers}) {
    if (index < 0 || index >= currentState.routeAlternatives.length) return;
    final alternative = currentState.routeAlternatives[index];
    onStateChange(currentState.copyWith(
        routeInfo: alternative.routeInfo, selectedAlternativeIndex: index));
    onStepIndexChange(0);
    onDistanceChange(0.0);
    updateLayers(force: true);
  }
  static Future<void> toggleNavigation(
      {required MapState currentState,
      required void Function(MapState) onStateChange,
      required MapLibreMapController? mapController,
      required double navigationRotation,
      required bool isFollowingUser,
      required void Function(bool) onFollowingChange,
      required Future<void> Function({bool force}) updateLayers}) async {
    if (mapController == null) return;
    MapState newState = currentState;
    if (!currentState.isNavigating && currentState.currentLocation == null) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        newState = newState.copyWith(
            currentLocation: LatLng(pos.latitude, pos.longitude));
      } catch (_) {}
    }
    final newIsNavigating = !newState.isNavigating;
    onFollowingChange(newIsNavigating);
    if (!newIsNavigating) {
      mapController.animateCamera(CameraUpdate.bearingTo(0));
      mapController.animateCamera(CameraUpdate.tiltTo(0));
      NotificationService.cancelNavigationNotification();
    }
    onStateChange(newState.copyWith(isNavigating: newIsNavigating));
    if (newIsNavigating && newState.currentLocation != null) {
      mapController.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(
              target: newState.currentLocation!,
              zoom: 17.5,
              tilt: 65,
              bearing: navigationRotation)),
          duration: const Duration(milliseconds: 2000));
    }
    await updateLayers(force: true);
  }
  static void clearRoute(
      {required MapState currentState,
      required void Function(MapState) onStateChange,
      required void Function(int) onStepIndexChange,
      required void Function(double) onDistanceChange,
      required Future<void> Function({bool force}) updateLayers}) {
    onStateChange(currentState.copyWith(
        destinationLocation: null,
        routeInfo: RouteInfo.empty,
        isNavigating: false,
        isRouting: false));
    onStepIndexChange(0);
    onDistanceChange(0.0);
    NotificationService.cancelNavigationNotification();
    updateLayers();
  }
  static void updateNavigationPerspective(
      {required Position position,
      required MapState currentState,
      required MapLibreMapController? mapController,
      required double navigationRotation,
      required void Function(double) onRotationChange,
      required Future<void> Function({bool force}) updateLayers}) {
    if (mapController == null || currentState.currentLocation == null) return;
    bool isVehicle = currentState.travelMode == TravelMode.driving ||
        currentState.travelMode == TravelMode.motorcycle;
    if ((isVehicle && currentState.currentSpeed > 4.0) ||
        navigationRotation == 0.0) {
      if (position.heading >= 0.0) onRotationChange(position.heading);
    }
    updateCameraFromCurrentState(
        currentState: currentState,
        mapController: mapController,
        navigationRotation: navigationRotation);
    updateLayers();
  }
  static void updateCameraFromCurrentState(
      {required MapState currentState,
      required MapLibreMapController? mapController,
      required double navigationRotation}) {
    if (mapController == null || currentState.currentLocation == null) return;
    final speedKmH = currentState.currentSpeed;
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
        currentState.currentLocation!.latitude + latOffset,
        currentState.currentLocation!.longitude + lngOffset);
    mapController.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
            target: offsetCenter,
            zoom: targetZoom,
            tilt: targetTilt,
            bearing: navigationRotation)),
        duration: const Duration(milliseconds: 200));
  }
  static void updateGuidance(
      {required Position position,
      required MapState currentState,
      required void Function(MapState) onStateChange,
      required int currentStepIndex,
      required void Function(int) onStepIndexChange,
      required double distanceToNextStep,
      required void Function(double) onDistanceChange,
      required DateTime? lastNotificationTime,
      required String? lastNotificationText,
      required void Function(DateTime?) onNotificationTimeChange,
      required void Function(String?) onNotificationTextChange}) {
    if (currentState.routeInfo.steps.isEmpty ||
        currentStepIndex >= currentState.routeInfo.steps.length) return;
    final currentStep = currentState.routeInfo.steps[currentStepIndex];
    final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        currentStep.location.latitude,
        currentStep.location.longitude);
    onStateChange(currentState.copyWith(distance: distance));
    onDistanceChange(distance);
    final distanceText = distance > 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';
    if (distance < AppConstants.stepAdvanceDistanceMeters &&
        currentStepIndex < currentState.routeInfo.steps.length - 1) {
      final newStepIndex = currentStepIndex + 1;
      onStepIndexChange(newStepIndex);
      VoiceNavigationService.speakTurnInstruction(
          currentState.routeInfo.steps[newStepIndex].instruction, distanceText);
    }
    final now = DateTime.now();
    final updateKey = '${currentStep.instruction}-$distanceText';
    if (lastNotificationTime == null ||
        now.difference(lastNotificationTime).inMilliseconds >
            AppConstants.notificationThrottleMs ||
        lastNotificationText != updateKey) {
      onNotificationTimeChange(now);
      onNotificationTextChange(updateKey);
      NotificationService.showNavigationNotification(
          instruction: currentStep.instruction, distance: distanceText);
      VoiceNavigationService.speakTurnInstruction(
          currentStep.instruction, distanceText);
    }
  }
}
