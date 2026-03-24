import 'package:flutter/services.dart'; // Required for PlatformException
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll; // Keep for models
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/map/screens/next_where_to_screen.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/widgets/profile_bottom_sheet.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/profile_service.dart';
import 'package:mapy/services/search_history_service.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';
import 'package:mapy/services/notification_service.dart';
import 'package:mapy/features/map/utils/map_icon_helper.dart';
import 'package:mapy/features/map/widgets/navigation_overlay.dart';
import 'package:mapy/features/map/widgets/map_controls_overlay.dart';

/// Helper extensions to bridge between latlong2 and maplibre_gl
extension LatLngllExt on ll.LatLng {
  LatLng toLibre() => LatLng(latitude, longitude);
}

extension LatLngmlExt on LatLng {
  ll.LatLng toLl2() => ll.LatLng(latitude, longitude);
}

/// The primary map screen of the application.
/// Manages the map state, user location, routing logic, and integration
/// with modular map widgets and the profile drawer.
class MainMapScreen extends StatefulWidget {
  /// The display name of the authenticated user.
  final String userName;

  const MainMapScreen({super.key, required this.userName});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

/// Available styles for the map tiles.
enum MapStyle { street, satellite, terrain }

class _MainMapScreenState extends State<MainMapScreen> with SingleTickerProviderStateMixin {
  // ── CORE STATE ─────────────────────────────────────────────────────────────

  MapLibreMapController? _mapController;
  MapStyle _currentStyle = MapStyle.street;

  LatLng? _currentLocation;
  LatLng? _previousLocation; // For interpolation
  AnimationController? _glideController;
  Animation<double>? _glideAnimation;
  ll.LatLng? _homeLocation;
  ll.LatLng? _workLocation;
  String? _avatarUrl;
  List<PlaceResult> _searchHistory = [];

  /// List of user-defined favorite locations (shortcuts).
  List<Map<String, dynamic>> _customPins = [];

  // ── DESTINATION & ROUTING ─────────────────────────────────────────────────

  LatLng? _destinationLocation;
  double _navigationRotation = 0.0;
  bool _isFollowingUser = false;
  int _currentStepIndex = 0;
  double _distanceToNextStep = 0.0; // in meters
  RouteInfo _routeInfo = RouteInfo.empty;
  bool _isRouting = false;
  TravelMode _travelMode = TravelMode.driving;
  bool _isNavigating = false;
  bool _isIconsLoaded = false;
  bool _isUpdatingLayers = false;
  final ValueNotifier<double> _bearingNotifier = ValueNotifier(0.0);
  final ValueNotifier<LatLng?> _locationNotifier = ValueNotifier(null);
  final ValueNotifier<double> _distanceNotifier = ValueNotifier(0.0);
  bool _is3dMode = true;
  DateTime? _lastLayerUpdateTime;
  StreamSubscription<Position>? _positionSubscription;

  // ── TILE STYLEs ───────────────────────────────────────────────────────

  final String _osmStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  final String _darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

  // Satellite Style JSON (ESRI World Imagery)
  final String _satelliteStyleJson = '''
  {
    "version": 8,
    "sources": {
      "satellite": {
        "type": "raster",
        "tiles": ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],
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

  // Terrain Style JSON (OpenTopoMap)
  final String _terrainStyleJson = '''
  {
    "version": 8,
    "sources": {
      "terrain": {
        "type": "raster",
        "tiles": [
          "https://a.tile.opentopomap.org/{z}/{x}/{y}.png",
          "https://b.tile.opentopomap.org/{z}/{x}/{y}.png",
          "https://c.tile.opentopomap.org/{z}/{x}/{y}.png"
        ],
        "tileSize": 256,
        "attribution": "Map data: © OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)"
      }
    },
    "layers": [
      {
        "id": "terrain",
        "type": "raster",
        "source": "terrain",
        "minzoom": 0,
        "maxzoom": 17
      }
    ]
  }
  ''';

  @override
  void initState() {
    super.initState();
    _glideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Match GPS update frequency
    );
    _loadSavedProfile();
    _relocateMe();
    _loadSettings();
    _loadHistory();
    _startLocationTracking();
    NotificationService.initialize(); // Initialize Notifications
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _glideController?.dispose();
    _bearingNotifier.dispose();
    _locationNotifier.dispose();
    _distanceNotifier.dispose();
    super.dispose();
  }

  /// Loads persistent user preferences from SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStyle = prefs.getString('default_map_style') ?? 'street';
    
    if (!mounted) return;
    setState(() {
      if (savedStyle == 'satellite') {
        _currentStyle = MapStyle.satellite;
      } else if (savedStyle == 'terrain') {
        _currentStyle = MapStyle.terrain;
      } else {
        _currentStyle = MapStyle.street;
      }
    });
  }

  /// Refetches the user's profile data (home, work, avatar, etc.)
  Future<void> _loadSavedProfile() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _homeLocation = profile.home;
      _workLocation = profile.work;
      _avatarUrl = profile.avatarUrl;
      _customPins = profile.customPins;
    });
  }

  /// Loads locally saved search history.
  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.getHistory();
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  /// Toggles the visual style of the map.
  void _setMapStyle(MapStyle style) => setState(() => _currentStyle = style);

  // ── ROUTING LOGIC ─────────────────────────────────────────────────────────

  /// Opens the search screen and handles the navigation to the selected result.
  Future<void> _onWhereToTapped() async {
    final ll.LatLng? picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(builder: (_) => const NextWhereToScreen()),
    );
    if (picked == null || !mounted) return;
    _loadHistory(); // Refresh history after selection
    await _navigateTo(picked.toLibre());
  }

  /// Resets the current route and destination.
  void _clearRoute() {
    // If we are currently navigating, stop it first to reset the camera
    if (_isNavigating) {
      _toggleNavigation();
    }
    setState(() {
      _destinationLocation = null;
      _routeInfo = RouteInfo.empty;
      _isNavigating = false;
      _isRouting = false;
      _currentStepIndex = 0;
      _distanceToNextStep = 0.0;
    });
    _updateLayers(); // Remove from map!
    NotificationService.cancelNavigationNotification(); // Clear lockscreen guide
  }

  /// Calculates and displays a route from the current location to [loc].
  Future<void> _navigateTo(LatLng loc) async {
    if (_currentLocation == null) return;
    setState(() => _isRouting = true);

    try {
      final info = await GeocodingService.getRoute(
        _currentLocation!.toLl2(), 
        loc.toLl2(),
        mode: _travelMode,
      );
      if (!mounted) return;
      setState(() {
        _destinationLocation = loc;
        _routeInfo = info;
        _isRouting = false;
        _currentStepIndex = 0;
        _distanceToNextStep = 0.0;
      });

      if (info.hasRoute) {
        final mlBounds = LatLngBounds(
          southwest: ll.LatLng(
            math.min(_currentLocation!.latitude, loc.latitude),
            math.min(_currentLocation!.longitude, loc.longitude),
          ).toLibre(),
          northeast: ll.LatLng(
            math.max(_currentLocation!.latitude, loc.latitude),
            math.max(_currentLocation!.longitude, loc.longitude),
          ).toLibre(),
        );
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(mlBounds, left: 80, top: 80, right: 80, bottom: 80),
        );
        _updateLayers(); // Restore the blue line!
      } else {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.0));
        _updateLayers(); // Restore the pin!
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRouting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get route: $e')),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.0));
    }
  }
  /// Switches travel mode and recalculates route if destination is set.
  void _setTravelMode(TravelMode mode) {
    if (_travelMode == mode) return;
    setState(() => _travelMode = mode);
    
    if (_destinationLocation != null) {
      _navigateTo(_destinationLocation!);
    }
  }

  /// Toggles Active Navigation mode.
  void _toggleNavigation() {
    if (_mapController == null) return;

    setState(() {
      _isNavigating = !_isNavigating;
      _isFollowingUser = _isNavigating;
      if (!_isNavigating) {
        _navigationRotation = 0.0;
        _mapController!.animateCamera(CameraUpdate.bearingTo(0));
        _mapController!.animateCamera(CameraUpdate.tiltTo(0));
        NotificationService.cancelNavigationNotification(); // Clear on exit
      }
    });

    if (_isNavigating && _currentLocation != null) {
      // Re-start tracking with HIGH accuracy for navigation
      _startLocationTracking();
      
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 18.0, // Higher for precision
            tilt: 60,
            bearing: _navigationRotation,
          ),
        ),
        duration: const Duration(milliseconds: 1500),
      );
    } else if (!_isNavigating) {
      // Switch back to medium accuracy to save battery
      _startLocationTracking();
    }
    _updateLayers(); // Ensure markers stay during navigation
  }

  /// Toggles between 2D (0 tilt) and 3D (60 tilt) map perspective.
  void _toggleMapPerspective() {
    setState(() => _is3dMode = !_is3dMode);
    _mapController?.animateCamera(
      CameraUpdate.tiltTo(_is3dMode ? 60 : 0),
    );
  }

  // ── GEOLOCATION ────────────────────────────────────────────────────────────

  /// Listens for continuous location updates to support "Active Navigation".
  /// Listens for continuous location updates to support "Active Navigation".
  void _startLocationTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _isNavigating ? LocationAccuracy.bestForNavigation : LocationAccuracy.medium,
        distanceFilter: _isNavigating ? 2 : 5, 
      ),
    ).listen((Position position) {
      if (!mounted) return;
      final newLoc = LatLng(position.latitude, position.longitude);

      if (_currentLocation != null) {
        _previousLocation = _currentLocation;
        _glideController?.reset();
        _glideAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _glideController!, curve: Curves.linear),
        )..addListener(() {
          if (_previousLocation != null && _glideAnimation != null) {
            final t = _glideAnimation!.value;
            final lat = _previousLocation!.latitude + (newLoc.latitude - _previousLocation!.latitude) * t;
            final lng = _previousLocation!.longitude + (newLoc.longitude - _previousLocation!.longitude) * t;
            
            _locationNotifier.value = LatLng(lat, lng);
            _currentLocation = _locationNotifier.value; 

            if (_isNavigating && _isFollowingUser) {
              _updateNavigationPerspective(position);
              _updateGuidance(position);
            }
          }
        });
        _glideController?.forward();
      } else {
        _locationNotifier.value = newLoc;
        _currentLocation = newLoc;
      }
    });
  }

  /// Updates map zoom and tilt based on speed for a "Pro" feel.
  void _updateNavigationPerspective(Position position) {
    if (_mapController == null || _currentLocation == null) return;

    double speedKmH = position.speed * 3.6;
    double targetZoom = 18.0 - (speedKmH / 40).clamp(0, 3);
    double targetTilt = 45.0 + (speedKmH / 5).clamp(0, 15);

    if (position.heading != 0) {
      _navigationRotation = position.heading;
    }

    final double offsetDistance = 0.0015; 
    final double bearingRad = _navigationRotation * 3.14159 / 180;
    final latOffset = offsetDistance * (math.cos(bearingRad));
    final lngOffset = offsetDistance * (math.sin(bearingRad));
    
    final offsetCenter = LatLng(
      _currentLocation!.latitude + latOffset,
      _currentLocation!.longitude + lngOffset,
    );

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: offsetCenter,
          zoom: targetZoom,
          tilt: targetTilt,
          bearing: _navigationRotation,
        ),
      ),
      duration: const Duration(milliseconds: 100), // Reduced from 1000ms to eliminate stacking lag
    );
    _updateLayers(); // Move the arrow!
  }

  /// Calculates distance to the next waypoint and advances instructions.
  void _updateGuidance(Position position) {
    if (_routeInfo.steps.isEmpty || _currentStepIndex >= _routeInfo.steps.length) return;

    final currentStep = _routeInfo.steps[_currentStepIndex];
    
    // Calculate distance to the next maneuver location
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.location.latitude,
      currentStep.location.longitude,
    );

    _distanceNotifier.value = distance;
    _distanceToNextStep = distance;

    // Update Live Lockscreen Guidance
    final distanceText = _distanceToNextStep > 1000 
        ? '${(_distanceToNextStep / 1000).toStringAsFixed(1)} km'
        : '${_distanceToNextStep.round()} m';
        
    NotificationService.showNavigationNotification(
      instruction: currentStep.instruction,
      distance: distanceText,
    );

    // Auto-advance if within 30 meters of the step's endpoint
    if (distance < 30 && _currentStepIndex < _routeInfo.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  /// Requests location permissions and centers the map on the user.
  Future<void> _relocateMe() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions denied.')));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions permanently denied.')));
        return;
      }
      if (!mounted) return;
      final position = await Geolocator.getCurrentPosition();
      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = newLoc);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLoc,
            zoom: 18.0,
            tilt: 45,
          ),
        ),
        duration: const Duration(milliseconds: 1200),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Location Error: $e')));
    }
  }

  // ── SHORTCUT MANAGEMENT (HOME / WORK) ─────────────────────────────────────

  /// Interacts with the Home/Work buttons based on their current state.
  void _handleLocationButton(String type) {
    final currentLoc = type == 'home' ? _homeLocation : _workLocation;
    if (currentLoc == null) {
      _openPicker(type);
    } else {
      _showLocationSheet(type, currentLoc.toLibre());
    }
  }

  /// Opens the picker for setting Home/Work.
  void _openPicker(String type) async {
    final picked = await Navigator.push<ll.LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          title: 'Set ${type.toUpperCase()}',
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      if (type == 'home') {
        _homeLocation = picked;
      } else {
        _workLocation = picked;
      }
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(picked.toLibre(), 15.0));
    _updateLayers();
    String? error;
    if (type == 'home') {
      error = await ProfileService.saveHomeLocation(picked);
    } else {
      error = await ProfileService.saveWorkLocation(picked);
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save to cloud: $error'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${type == 'home' ? 'Home' : 'Work'} saved to cloud ☁️'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  /// Displays an action sheet for an existing Home/Work location.
  void _showLocationSheet(String type, LatLng loc) {
    final isHome = type == 'home';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Icon(isHome ? Icons.home_rounded : Icons.work_rounded,
                      color: isHome ? Colors.blue : Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(isHome ? 'Home' : 'Work',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                    '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.5))),
              ),
              const SizedBox(height: 16),
              Divider(
                  color: isDark ? Colors.white12 : Colors.black12, height: 1),
              _sheetTile(
                icon: Icons.navigation_rounded,
                iconColor: Colors.blueAccent,
                label: 'Go to ${isHome ? 'Home' : 'Work'}',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _navigateTo(loc);
                },
              ),
              _sheetTile(
                icon: Icons.edit_location_alt_rounded,
                iconColor: Colors.green,
                label: 'Change location',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openPicker(type);
                },
              ),
              _sheetTile(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.redAccent,
                label: 'Clear ${isHome ? 'Home' : 'Work'}',
                textColor: Colors.redAccent,
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  setState(() {
                    if (isHome) {
                      _homeLocation = null;
                    } else {
                      _workLocation = null;
                    }
                  });
                  String? error;
                  if (isHome) {
                    error = await ProfileService.clearHomeLocation();
                  } else {
                    error = await ProfileService.clearWorkLocation();
                  }

                  if (!mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to clear location: $error'),
                      backgroundColor: Colors.redAccent,
                    ));
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('${isHome ? 'Home' : 'Work'} location cleared.'),
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a standard tile for the location action sheet.
  Widget _sheetTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 14, color: textColor.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Map Layer (3D MapLibre) ────────────────────────────
          RepaintBoundary(
            child: MapLibreMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(51.5, -0.09),
                zoom: 13.0,
              ),
              styleString: _getMapStyleString(isDark),
              onMapCreated: (controller) {
                _mapController = controller;
                _relocateMe();
              },
              onStyleLoadedCallback: () async {
                await MapIconHelper.addStandardIcons(_mapController!);
                _updateLayers();
              },
              trackCameraPosition: true, 
              myLocationEnabled: !_isNavigating, 
              myLocationTrackingMode: _isFollowingUser 
                  ? MyLocationTrackingMode.trackingGps 
                  : MyLocationTrackingMode.none,
              compassEnabled: false,
              onCameraIdle: () {
                if (mounted && _mapController != null) {
                  _mapController!.getVisibleRegion();
                  _bearingNotifier.value = _mapController!.cameraPosition?.bearing ?? 0.0;
                }
              },
              onMapClick: (point, latlng) {
                if (!_isNavigating) {
                   _navigateTo(latlng);
                }
              },
            ),
          ),

          // ── Integrated Overlays ──────────────────────────────────────────
          
          // 1. Top Search & Shortcuts
          if (!_isNavigating)
            Positioned(
              top: 60, left: 16, right: 16,
              child: _buildSearchAndShortcuts(isDark),
            ),

          // 2. Top Navigation Guidance (Only when navigating)
          if (_isNavigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12, right: 12,
              child: ValueListenableBuilder<LatLng?>(
                valueListenable: _locationNotifier,
                builder: (context, location, _) {
                  return RepaintBoundary(
                    child: NavigationGuidanceBar(
                      routeInfo: _routeInfo,
                      currentStepIndex: _currentStepIndex,
                      distanceToNextStepNotifier: _distanceNotifier,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),

          // 7. Destination Marker Info
          if (_destinationLocation != null && !_isNavigating)
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey.shade900 : Colors.white).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Destination set',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ──────────────────────────────────────────────────────────────────
          // UNIFIED BOTTOM STACK (Buttons + Trip Bar + Route Info)
          // ──────────────────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Right-side Control Buttons (Compass, Locate Me, 2D/3D)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compass
                        ValueListenableBuilder<double>(
                          valueListenable: _bearingNotifier,
                          builder: (context, bearing, _) {
                            return Opacity(
                              opacity: bearing.abs() < 0.1 ? 0.0 : 1.0, 
                              child: Transform.rotate(
                                angle: -bearing * (math.pi / 180),
                                child: MapActionButton(
                                  icon: Icons.explore_rounded,
                                  onPressed: () {
                                    if (_mapController != null) {
                                      _mapController!.animateCamera(CameraUpdate.bearingTo(0));
                                      _bearingNotifier.value = 0.0;
                                    }
                                  },
                                  color: Colors.redAccent,
                                  isDark: isDark,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Locate Me
                        MapControlsOverlay(
                          isNavigating: _isNavigating,
                          onRelocate: _relocateMe,
                          onLayers: _showLayersMenu, 
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        // 2D/3D Perspective
                        MapActionButton(
                          icon: _is3dMode ? Icons.view_in_ar_rounded : Icons.flatware_rounded,
                          onPressed: _toggleMapPerspective,
                          color: Colors.orangeAccent,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16), // Gap between buttons and bar

                // 2. Greeting / Trip Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey('trip_bar_${_routeInfo.hasRoute}_$_isNavigating'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
                              .withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black45 : Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isNavigating
                                        ? 'ACTIVE NAVIGATION'
                                        : (_routeInfo.hasRoute ? 'TRIP TO DESTINATION' : 'READY TO GO?'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isNavigating ? Colors.blueAccent : (isDark ? Colors.white38 : Colors.black38),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isNavigating
                                        ? 'Safety first!'
                                        : (_routeInfo.hasRoute ? 'Destination set' : 'Hello, ${widget.userName}!'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_routeInfo.hasRoute && !_isNavigating)
                              ElevatedButton.icon(
                                onPressed: _toggleNavigation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                icon: const Icon(Icons.navigation_rounded, size: 20),
                                label: const Text(
                                  'START',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            if (_isNavigating)
                              ElevatedButton(
                                onPressed: _toggleNavigation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'EXIT',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Spacing + Route Info Panel
                if (_routeInfo.hasRoute) ...[
                  const SizedBox(height: 12), // PERFECT 12px gap
                  RepaintBoundary(
                    child: RouteInfoPanel(
                      routeInfo: _routeInfo,
                      isNavigating: _isNavigating,
                      travelMode: _travelMode,
                      isDark: isDark,
                      onClear: _clearRoute,
                      onModeSelect: _setTravelMode,
                    ),
                  ),
                ],

                // 4. Default Bottom Margin (for idle state)
                if (!_routeInfo.hasRoute)
                  const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CUSTOM SHORTCUT MANAGEMENT ───────────────────────────────────────────

  /// Adds a new personalized shortcut to the list.
  Future<void> _addCustomPin() async {
    final String? label = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Favorite Place'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'e.g. Grandma\'s House'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (label == null || label.isEmpty) return;

    if (!mounted) return;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const PickLocationScreen(title: 'Pick Favorite Location')),
    );

    if (result != null) {
      final newPin = {'label': label, 'lat': result.latitude, 'lon': result.longitude};
      setState(() {
        _customPins = [..._customPins, newPin];
      });
      final error = await ProfileService.saveCustomPins(_customPins);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to sync favorite to cloud: $error'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  /// Deletes an existing custom shortcut.
  Future<void> _deleteCustomPin(Map<String, dynamic> pin) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shortcut?'),
        content: Text('Do you want to remove "${pin['label']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _customPins.remove(pin);
        _customPins = [..._customPins];
      });
      final error = await ProfileService.saveCustomPins(_customPins);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update cloud: $error'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  /// Displays the profile menu in a modern, Google Maps-style bottom sheet.
  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileBottomSheet(
        userName: widget.userName,
        onProfileUpdate: _loadSavedProfile,
      ),
    );
  }

  /// Builds a map style selection tile.
  void _showLayersMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLayerSelector(
        currentStyle: _currentStyle,
        isDark: isDark,
        onStyleSelected: _setMapStyle,
      ),
    );
  }

  // ── SUB-WIDGETS ────────────────────────────────────────────────────────────

  Widget _buildSearchAndShortcuts(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapSearchBar(
          isDark: isDark,
          isRouting: _isRouting,
          avatarUrl: _avatarUrl,
          onSearchTap: _onWhereToTapped,
          onAvatarTap: _showProfileBottomSheet,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_searchHistory.isNotEmpty)
                  ..._searchHistory.take(2).map((place) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: LocationChip(
                      type: 'recent',
                      icon: Icons.history_rounded,
                      label: place.shortName,
                      isSet: true,
                      activeColor: Colors.purple,
                      isDark: isDark,
                      onTap: () => _navigateTo(LatLng(place.lat, place.lon)),
                    ),
                  )),
                LocationChip(
                  type: 'home',
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSet: _homeLocation != null,
                  activeColor: Colors.blue,
                  isDark: isDark,
                  onTap: () => _handleLocationButton('home'),
                ),
                const SizedBox(width: 6),
                LocationChip(
                  type: 'work',
                  icon: Icons.work_rounded,
                  label: 'Work',
                  isSet: _workLocation != null,
                  activeColor: Colors.orange,
                  isDark: isDark,
                  onTap: () => _handleLocationButton('work'),
                ),
                ..._customPins.map((pin) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: LocationChip(
                    type: 'custom',
                    icon: Icons.place_rounded,
                    label: pin['label'],
                    isSet: true,
                    activeColor: Colors.teal,
                    isDark: isDark,
                    onTap: () => _navigateTo(LatLng(pin['lat'], pin['lon'])),
                    onLongPress: () => _deleteCustomPin(pin),
                  ),
                )),
                const SizedBox(width: 6),
                AddShortcutButton(isDark: isDark, onTap: _addCustomPin),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Map Style Toggle (Professional alignment below chips)
        Align(
          alignment: Alignment.centerRight,
          child: MapActionButton(
            icon: Icons.layers_rounded,
            onPressed: _showLayersMenu,
            color: Colors.blueAccent,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ── STYLE HELPERS ─────────────────────────────────────────────────────────

  String _getMapStyleString(bool isDark) {
    switch (_currentStyle) {
      case MapStyle.satellite: return _satelliteStyleJson;
      case MapStyle.terrain: return _terrainStyleJson;
      case MapStyle.street: return isDark ? _darkStyleUrl : _osmStyleUrl;
    }
  }



  /// Updates all markers and route lines on the MapLibre map.
  Future<void> _updateLayers() async {
    if (_mapController == null || _isUpdatingLayers || !mounted) return;
    
    // Throttle to 1000ms to prevent native crashes and reduce CPU lag during rapid movement
    final now = DateTime.now();
    if (_lastLayerUpdateTime != null && 
        now.difference(_lastLayerUpdateTime!).inMilliseconds < 1000) {
      return;
    }

    _isUpdatingLayers = true;
    _lastLayerUpdateTime = now;
    
    try {
      // Safety: ensure icons are loaded if possible
      if (!_isIconsLoaded) {
        try {
          await MapIconHelper.addStandardIcons(_mapController!);
          _isIconsLoaded = true;
        } catch (e) {
          debugPrint('Map icons failed to load: $e');
          _isIconsLoaded = true; // prevent infinite retry
        }
      }

      // 1. Clear everything with a small buffer for native sync
      await _mapController!.clearSymbols();
      await _mapController!.clearLines();
      await _mapController!.clearCircles();
      
      // Give the native engine a tiny moment to stabilize after clearing
      await Future.delayed(const Duration(milliseconds: 10));
      if (!mounted) return;

      // 2. Add Route Polyline
      if (_routeInfo.hasRoute && _routeInfo.points.isNotEmpty) {
        try {
          await _mapController!.addLine(
            LineOptions(
              geometry: _routeInfo.points.map((p) => p.toLibre()).toList(),
              lineColor: "#448AFF", 
              lineWidth: 6.0,
              lineOpacity: 0.8,
              lineJoin: "round",
            ),
          );
        } on PlatformException catch (e) {
          debugPrint('Suppressed line rendering race condition: $e');
        }
      }

      // 3. Add Destination Marker
      if (_destinationLocation != null) {
        try {
          await _mapController!.addCircle(
            CircleOptions(
              geometry: _destinationLocation!,
              circleColor: "#FF5252",
              circleRadius: 8.0,
              circleStrokeWidth: 3.0,
              circleStrokeColor: "#FFFFFF",
            ),
          );

          await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _destinationLocation!,
              iconImage: "dest-pin", 
              iconSize: 1.0,
              iconAnchor: "bottom",
            ),
          );
        } on PlatformException catch (e) {
          debugPrint('Suppressed marker rendering race condition: $e');
        }
      }

      // 4. Add User Arrow
      if (_isNavigating && _currentLocation != null) {
        try {
          await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _currentLocation!,
              iconImage: "user-arrow",
              iconSize: 0.8,
              iconRotate: _navigationRotation,
            ),
          );
        } on PlatformException catch (e) {
          debugPrint('Suppressed arrow rendering race condition: $e');
        }
      }

      // 5. Add Home/Work
      if (!_isNavigating) {
        try {
          if (_homeLocation != null) {
            await _mapController!.addSymbol(
              SymbolOptions(
                geometry: _homeLocation!.toLibre(),
                iconImage: "home-pin",
                iconSize: 0.8,
              ),
            );
          }
          if (_workLocation != null) {
            await _mapController!.addSymbol(
              SymbolOptions(
                geometry: _workLocation!.toLibre(),
                iconImage: "work-pin",
                iconSize: 0.8,
              ),
            );
          }
        } on PlatformException catch (e) {
          debugPrint('Suppressed shortcut rendering race condition: $e');
        }
      }
    } catch (e) {
      debugPrint('General error updating map layers: $e');
    } finally {
      _isUpdatingLayers = false;
    }
  }
}

