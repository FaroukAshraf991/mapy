import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/features/map/widgets/map_controls_overlay.dart';
import 'package:mapy/features/map/widgets/navigation_overlay.dart';
import 'package:mapy/blocs/map/map_cubit.dart';
import 'package:mapy/blocs/map/map_state.dart';

class MapBuilder {
  static Widget buildMap({
    required BuildContext context,
    required MapCubit mapCubit,
    required MapState state,
    required void Function(MapLibreMapController) onMapCreated,
    required VoidCallback onStyleLoaded,
    required VoidCallback onCameraIdle,
    required void Function(dynamic, LatLng) onMapClick,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: MapLibreMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
          zoom: AppConstants.defaultZoom,
        ),
        styleString: mapCubit.getMapStyleString(isDark),
        onMapCreated: (controller) => onMapCreated(controller),
        onStyleLoadedCallback: onStyleLoaded,
        trackCameraPosition: true,
        myLocationEnabled: false,
        compassEnabled: false,
        onCameraIdle: onCameraIdle,
        onMapClick: onMapClick,
      ),
    );
  }

  static Widget buildTopOverlay({
    required BuildContext context,
    required String userName,
    required MapCubit mapCubit,
    required MapState state,
    required VoidCallback onSearchTap,
    required VoidCallback onAvatarTap,
    required Function(String) onCategoryTap,
    Function(String)? onVoiceResult,
    required VoidCallback onSwapEndpoints,
    VoidCallback? onOriginTap,
    VoidCallback? onDestinationTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TopSearchOverlay(
      userName: userName,
      isDark: isDark,
      isRouting: state.isRouting,
      showTopUI: !state.routeInfo.hasRoute,
      destinationName: state.destinationName,
      originName: state.originName,
      onSearchTap: onSearchTap,
      onAvatarTap: onAvatarTap,
      onCategoryTap: onCategoryTap,
      onVoiceResult: onVoiceResult,
      onSwapEndpoints: onSwapEndpoints,
      onOriginTap: onOriginTap,
      onDestinationTap: onDestinationTap,
    );
  }

  static Widget buildTopLayersButton({
    required BuildContext context,
    required MapState state,
    required MapCubit mapCubit,
    required VoidCallback onRelocate,
    required VoidCallback onTogglePerspective,
    required VoidCallback onLayers,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + context.h(200),
      right: context.w(16),
      child: MapControlsOverlay(
        isDark: isDark,
        isNavigating: state.isNavigating,
        is3dMode: state.is3dMode,
        hasRoute: state.routeInfo.hasRoute,
        bearing: state.bearing,
        onRelocate: onRelocate,
        onLayers: onLayers,
        onTogglePerspective: onTogglePerspective,
        onResetBearing: () {
          if (mapCubit.mapController != null) {
            mapCubit.mapController!.animateCamera(CameraUpdate.bearingTo(0));
            mapCubit.mapController!.animateCamera(CameraUpdate.tiltTo(0));
            mapCubit.updateBearing(0.0);
          }
        },
        showLayersButton: false,
        showAtTop: true,
        showOnlyLayers: true,
      ),
    );
  }

  static Widget buildNavigationGuidance({
    required BuildContext context,
    required MapState state,
    required MapCubit mapCubit,
  }) {
    if (!state.isNavigating) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + context.h(10),
      left: context.w(12),
      right: context.w(12),
      child: RepaintBoundary(
        child: NavigationGuidanceBar(
          routeInfo: state.routeInfo,
          currentStepIndex: mapCubit.currentStepIndex,
          distanceToNextStep: state.distance,
          isDark: isDark,
          currentSpeed: state.currentSpeed,
        ),
      ),
    );
  }

  static Widget buildBottomOverlay({
    required BuildContext context,
    required MapState state,
    required MapCubit mapCubit,
    required VoidCallback onWhereToTapped,
    required VoidCallback onStartNavigation,
    required VoidCallback onRelocate,
    required VoidCallback onTogglePerspective,
    required VoidCallback onClearRoute,
    required Function(TravelMode) onModeSelect,
    required VoidCallback onShowAlternatives,
    required VoidCallback onShareLocation,
    required VoidCallback onPreview,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomMapControls(
      isDark: isDark,
      isNavigating: state.isNavigating,
      is3dMode: state.is3dMode,
      hasRoute: state.routeInfo.hasRoute,
      isFetchingRoute: state.isFetchingRoute,
      bearing: state.bearing,
      routeInfo: state.routeInfo,
      travelMode: state.travelMode,
      locationFollowMode: state.locationFollowMode,
      tripBar: TripBar(
        hasRoute: state.routeInfo.hasRoute,
        isNavigating: state.isNavigating,
        isDark: isDark,
        isSwapped: state.isRouteSwapped ||
            (state.startName != null && state.startName != 'Your location'),
        onTap: onWhereToTapped,
        onStartNavigation: onStartNavigation,
        onExitNavigation: onStartNavigation,
        onPreview: onPreview,
        routeInfo: state.routeInfo.hasRoute ? state.routeInfo : null,
        travelMode: state.travelMode,
        isFetchingRoute: state.isFetchingRoute,
      ),
      onRelocate: onRelocate,
      onLayers: () {},
      onTogglePerspective: onTogglePerspective,
      onResetBearing: () {
        if (mapCubit.mapController != null) {
          mapCubit.mapController!.animateCamera(CameraUpdate.bearingTo(0));
          mapCubit.updateBearing(0.0);
        }
      },
      onClearRoute: onClearRoute,
      onModeSelect: onModeSelect,
      routeAlternatives: state.routeAlternatives,
      selectedAlternativeIndex: state.selectedAlternativeIndex,
      onShowAlternatives: onShowAlternatives,
      onShareLocation: onShareLocation,
      onStartNavigation: onStartNavigation,
      onPreview: onPreview,
      isSwapped: state.isRouteSwapped ||
          (state.startName != null && state.startName != 'Your location'),
    );
  }
}
