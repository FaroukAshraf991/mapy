import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mapy/features/map/widgets/profile_bottom_sheet.dart';
import 'package:mapy/services/notification_service.dart';
import 'package:mapy/services/voice_navigation_service.dart';
import 'package:mapy/services/location_share_service.dart';
import 'package:mapy/blocs/map/map_cubit.dart';
import 'package:mapy/blocs/map/map_state.dart';
import 'package:mapy/features/map/utils/map_actions_helper.dart';
import 'package:mapy/features/map/widgets/map_builder.dart';
import 'package:mapy/features/map/widgets/layers_overlay.dart';
import 'package:mapy/features/map/screens/route_preview_screen.dart';

class MainMapScreen extends StatefulWidget {
  final String userName;

  const MainMapScreen({super.key, required this.userName});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  late final MapCubit _mapCubit;
  late final MapActionsHelper _actions;

  @override
  void initState() {
    super.initState();
    _mapCubit = MapCubit();
    _actions = MapActionsHelper(
      mapCubit: _mapCubit,
      context: context,
      onStateChanged: () => setState(() {}),
      showSnackBar: _showSnackBar,
      isMounted: () => mounted,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _mapCubit.initialize();
    NotificationService.initialize();
    await VoiceNavigationService.initialize();
    _mapCubit.startLocationTracking();
  }

  @override
  void dispose() {
    _mapCubit.close();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: color ?? Colors.redAccent),
    );
  }

void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileBottomSheet(
        userName: widget.userName,
        onProfileUpdate: () {},
      ),
    ).then((_) => setState(() {}));
  }

  void _showLayersOverlay(BuildContext context, MapState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    LayersOverlay.show(
      context: context,
      currentStyle: state.currentStyle,
      isDark: isDark,
      showTraffic: state.showTraffic,
      showTransit: state.showTransit,
      showBiking: state.showBiking,
      onStyleSelected: (style) {
        _mapCubit.setMapStyle(style);
        setState(() {});
      },
      onTrafficToggle: (value) {
        _mapCubit.toggleTraffic();
        setState(() {});
      },
      onTransitToggle: (value) {
        _mapCubit.toggleTransit();
        setState(() {});
      },
      onBikingToggle: (value) {
        _mapCubit.toggleBiking();
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _mapCubit,
      child: Scaffold(
        body: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            return Stack(
              children: [
                MapBuilder.buildMap(
                  context: context,
                  mapCubit: _mapCubit,
                  state: state,
                  onMapCreated: (controller) {
                    _mapCubit.setMapController(controller);
                    _actions.onMapCreated(controller);
                  },
                  onStyleLoaded: _actions.onStyleLoaded,
                  onCameraIdle: _actions.onCameraIdle,
                  onMapClick: (point, latlng) =>
                      _actions.onMapClick(point, latlng),
                ),
                if (!state.isNavigating)
                  MapBuilder.buildTopOverlay(
                    context: context,
                    userName: widget.userName,
                    mapCubit: _mapCubit,
                    state: state,
                    onSearchTap: _actions.onWhereToTapped,
                    onAvatarTap: _showProfileBottomSheet,
                    onVoiceResult: _actions.onWhereToTappedWithQuery,
                    onCategoryTap: _actions.onCategoryTapped,
                    onSwapEndpoints: _actions.swapEndpoints,
                    onOriginTap: _actions.onChangeOriginTapped,
                    onDestinationTap: _actions.onWhereToTapped,
                  ),
                MapBuilder.buildTopLayersButton(
                  context: context,
                  state: state,
                  mapCubit: _mapCubit,
                  onRelocate: _actions.relocateMe,
                  onTogglePerspective: _actions.toggleMapPerspective,
                  onLayers: () => _showLayersOverlay(context, state),
                ),
                MapBuilder.buildNavigationGuidance(
                  context: context,
                  state: state,
                  mapCubit: _mapCubit,
                ),
                MapBuilder.buildBottomOverlay(
                  context: context,
                  state: state,
                  mapCubit: _mapCubit,
                  onWhereToTapped: _actions.onWhereToTapped,
                  onStartNavigation: _actions.toggleNavigation,
                  onRelocate: _actions.relocateMe,
                  onTogglePerspective: _actions.toggleMapPerspective,
                  onClearRoute: _actions.clearRoute,
                  onModeSelect: _actions.setTravelMode,
                  onShowAlternatives: _actions.showRouteAlternatives,
                  onShareLocation: () {
                    final currentLocation = _mapCubit.state.currentLocation;
                    if (currentLocation != null) {
                      LocationShareService.shareLocation(
                        latitude: currentLocation.latitude,
                        longitude: currentLocation.longitude,
                        placeName: 'My Current Location',
                      );
                    }
                  },
                  onPreview: () {
                    final routeInfo = _mapCubit.state.routeInfo;
                    if (routeInfo.hasRoute && routeInfo.steps.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoutePreviewScreen(
                            routeInfo: routeInfo,
                            originName:
                                _mapCubit.state.originName ?? 'Your location',
                            destinationName: _mapCubit.state.destinationName ??
                                'Destination',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
