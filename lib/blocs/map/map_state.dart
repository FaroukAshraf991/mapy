import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/models/route_info.dart';
import '../../models/place_result.dart';

class MapState {
  final MapStyle currentStyle;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
  final String? destinationName;
  final String? originName;
  final LatLng? startLocation;
  final String? startName;
  final bool isRouteSwapped;
  final ll.LatLng? homeLocation;
  final ll.LatLng? workLocation;
  final List<PlaceResult> searchHistory;
  final List<Map<String, dynamic>> customPins;
  final RouteInfo routeInfo;
  final List<RouteAlternative> routeAlternatives;
  final int selectedAlternativeIndex;
  final bool isRouting;
  final TravelMode travelMode;
  final bool isNavigating;
  final bool isFetchingRoute;
  final bool is3dMode;
  final double bearing;
  final double distance;
  final double currentSpeed;
  final bool showTraffic;
  final bool showTransit;
  final bool showBiking;
  final LocationFollowMode locationFollowMode;

  const MapState({
    this.currentStyle = MapStyle.street,
    this.currentLocation,
    this.destinationLocation,
    this.destinationName,
    this.originName,
    this.startLocation,
    this.startName,
    this.isRouteSwapped = false,
    this.homeLocation,
    this.workLocation,
    this.searchHistory = const [],
    this.customPins = const [],
    this.routeInfo = RouteInfo.empty,
    this.routeAlternatives = const [],
    this.selectedAlternativeIndex = 0,
    this.isRouting = false,
    this.travelMode = TravelMode.driving,
    this.isNavigating = false,
    this.isFetchingRoute = false,
    this.is3dMode = true,
    this.bearing = 0.0,
    this.distance = 0.0,
    this.currentSpeed = 0.0,
    this.showTraffic = false,
    this.showTransit = false,
    this.showBiking = false,
    this.locationFollowMode = LocationFollowMode.none,
  });

  MapState copyWith({
    MapStyle? currentStyle,
    LatLng? currentLocation,
    LatLng? destinationLocation,
    Object? destinationName = _sentinel,
    Object? originName = _sentinel,
    Object? startLocation = _sentinel,
    Object? startName = _sentinel,
    bool? isRouteSwapped,
    ll.LatLng? homeLocation,
    ll.LatLng? workLocation,
    List<PlaceResult>? searchHistory,
    List<Map<String, dynamic>>? customPins,
    RouteInfo? routeInfo,
    List<RouteAlternative>? routeAlternatives,
    int? selectedAlternativeIndex,
    bool? isRouting,
    TravelMode? travelMode,
    bool? isNavigating,
    bool? isFetchingRoute,
    bool? is3dMode,
    double? bearing,
    double? distance,
    double? currentSpeed,
    bool? showTraffic,
    bool? showTransit,
    bool? showBiking,
    LocationFollowMode? locationFollowMode,
  }) {
    return MapState(
      currentStyle: currentStyle ?? this.currentStyle,
      currentLocation: currentLocation ?? this.currentLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationName: identical(destinationName, _sentinel)
          ? this.destinationName
          : destinationName as String?,
      originName: identical(originName, _sentinel)
          ? this.originName
          : originName as String?,
      startLocation: identical(startLocation, _sentinel)
          ? this.startLocation
          : startLocation as LatLng?,
      startName: identical(startName, _sentinel)
          ? this.startName
          : startName as String?,
      isRouteSwapped: isRouteSwapped ?? this.isRouteSwapped,
      homeLocation: homeLocation ?? this.homeLocation,
      workLocation: workLocation ?? this.workLocation,
      searchHistory: searchHistory ?? this.searchHistory,
      customPins: customPins ?? this.customPins,
      routeInfo: routeInfo ?? this.routeInfo,
      routeAlternatives: routeAlternatives ?? this.routeAlternatives,
      selectedAlternativeIndex:
          selectedAlternativeIndex ?? this.selectedAlternativeIndex,
      isRouting: isRouting ?? this.isRouting,
      travelMode: travelMode ?? this.travelMode,
      isNavigating: isNavigating ?? this.isNavigating,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      is3dMode: is3dMode ?? this.is3dMode,
      bearing: bearing ?? this.bearing,
      distance: distance ?? this.distance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      showTraffic: showTraffic ?? this.showTraffic,
      showTransit: showTransit ?? this.showTransit,
      showBiking: showBiking ?? this.showBiking,
      locationFollowMode: locationFollowMode ?? this.locationFollowMode,
    );
  }
}

const Object _sentinel = Object();
