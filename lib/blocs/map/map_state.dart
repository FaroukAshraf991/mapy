import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../features/map/models/map_enums.dart';
import '../../features/map/models/route_info.dart';
import '../../models/place_result.dart';

class MapState {
  final MapStyle currentStyle;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
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

  const MapState({
    this.currentStyle = MapStyle.street,
    this.currentLocation,
    this.destinationLocation,
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
  });

  MapState copyWith({
    MapStyle? currentStyle,
    LatLng? currentLocation,
    LatLng? destinationLocation,
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
  }) {
    return MapState(
      currentStyle: currentStyle ?? this.currentStyle,
      currentLocation: currentLocation ?? this.currentLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
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
    );
  }
}
