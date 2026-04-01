import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:mapy/features/map/widgets/profile_bottom_sheet.dart';
import 'package:mapy/services/notification_service.dart';
import 'package:mapy/services/voice_navigation_service.dart';
import 'package:mapy/services/location_share_service.dart';
import 'package:mapy/features/map/utils/map_layer_manager.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/blocs/map/map_cubit.dart';
import 'package:mapy/blocs/map/map_state.dart';
import 'package:mapy/features/map/utils/map_actions_helper.dart';
import 'package:mapy/features/map/widgets/map_builder.dart';

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
    await _actions.relocateMe();
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

  void _handleLocationButton(String type) {
    final loc = type == 'home'
        ? _mapCubit.state.homeLocation
        : _mapCubit.state.workLocation;
    if (loc == null) {
      _actions.openPicker(type);
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
        onChange: () => _actions.openPicker(type),
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
                  onMapCreated: () =>
                      _actions.onMapCreated(_mapCubit.mapController!),
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
                    onRecentsTap: () {},
                    onHomeTap: () => _handleLocationButton('home'),
                    onWorkTap: () => _handleLocationButton('work'),
                    onCustomPinTap: (pin) {
                      _mapCubit.navigateTo(LatLng(pin['lat'], pin['lon']));
                      setState(() {});
                    },
                    onCustomPinLongPress: _actions.deleteCustomPin,
                    onAddTap: _actions.addCustomPin,
                  ),
                MapBuilder.buildTopLayersButton(
                  context: context,
                  state: state,
                  mapCubit: _mapCubit,
                  onRelocate: _actions.relocateMe,
                  onTogglePerspective: _actions.toggleMapPerspective,
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
