import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/map/screens/next_where_to_screen.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/widgets/main_drawer.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/profile_service.dart';

class MainMapScreen extends StatefulWidget {
  final String userName;
  const MainMapScreen({super.key, required this.userName});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  final MapController _mapController = MapController();
  bool _isSatellite = false;

  LatLng? _currentLocation;
  LatLng? _homeLocation;
  LatLng? _workLocation;
  String? _avatarUrl;

  // ── Destination & Routing ─────────────────────────────────────────────────
  LatLng? _destinationLocation;
  RouteInfo _routeInfo = RouteInfo.empty;
  bool _isRouting = false;

  final String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  final String _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _relocateMe();
      _loadSavedProfile();
    });
  }

  Future<void> _loadSavedProfile() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _homeLocation = profile.home;
      _workLocation = profile.work;
      _avatarUrl = profile.avatarUrl;
    });
  }

  void _toggleSatellite() => setState(() => _isSatellite = !_isSatellite);

  // ── Routing ───────────────────────────────────────────────────────────────

  Future<void> _onWhereToTapped() async {
    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const NextWhereToScreen()),
    );
    if (picked == null || !mounted) return;
    await _navigateTo(picked);
  }

  void _clearRoute() {
    setState(() {
      _destinationLocation = null;
      _routeInfo = RouteInfo.empty;
    });
  }

  Future<void> _navigateTo(LatLng loc) async {
    setState(() {
      _destinationLocation = loc;
      _routeInfo = RouteInfo.empty;
      _isRouting = true;
    });

    if (_currentLocation != null) {
      final info = await GeocodingService.getRoute(_currentLocation!, loc);
      if (!mounted) return;
      setState(() {
        _routeInfo = info;
        _isRouting = false;
      });
      if (info.hasRoute) {
        final bounds = LatLngBounds.fromPoints([_currentLocation!, loc]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
        );
      } else {
        _mapController.move(loc, 15.0);
      }
    } else {
      setState(() => _isRouting = false);
      _mapController.move(loc, 15.0);
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

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
      _mapController.move(newLoc, 17.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Location Error: $e')));
    }
  }

  // ── Smart Home / Work ─────────────────────────────────────────────────────

  void _handleLocationButton(String type) {
    final currentLoc = type == 'home' ? _homeLocation : _workLocation;
    if (currentLoc == null) {
      _openPicker(type);
    } else {
      _showLocationSheet(type, currentLoc);
    }
  }

  Future<void> _openPicker(String type) async {
    final isHome = type == 'home';
    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
          builder: (_) => PickLocationScreen(
              title: isHome ? 'Pick Home Location' : 'Pick Work Location')),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isHome) {
        _homeLocation = picked;
      } else {
        _workLocation = picked;
      }
    });
    _mapController.move(picked, 15.0);
    if (isHome) {
      await ProfileService.saveHomeLocation(picked);
    } else {
      await ProfileService.saveWorkLocation(picked);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${isHome ? 'Home' : 'Work'} saved to cloud ☁️'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

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
                  if (isHome) {
                    await ProfileService.clearHomeLocation();
                  } else {
                    await ProfileService.clearWorkLocation();
                  }
                  if (!mounted) return;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    final bool hasRoute = _destinationLocation != null;

    return Scaffold(
      drawer: MainDrawer(userName: widget.userName),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09), initialZoom: 13.0),
            children: [
              ColorFiltered(
                colorFilter: isDark && !_isSatellite
                    ? const ColorFilter.matrix([
                        -1, 0, 0, 0, 255,
                        0, -1, 0, 0, 255,
                        0, 0, -1, 0, 255,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent, BlendMode.multiply),
                child: TileLayer(
                  urlTemplate: _isSatellite ? _satelliteUrl : _osmUrl,
                  userAgentPackageName: 'com.farouk991.mapy',
                ),
              ),
              if (_routeInfo.hasRoute)
                PolylineLayer(polylines: [
                  Polyline(
                      points: _routeInfo.points,
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      strokeWidth: 12),
                  Polyline(
                      points: _routeInfo.points,
                      color: Colors.blueAccent,
                      strokeWidth: 5),
                ]),
              MarkerLayer(markers: [
                if (_currentLocation != null)
                  Marker(
                      point: _currentLocation!,
                      width: 40, height: 40,
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.green, size: 40)),
                if (_homeLocation != null)
                  Marker(
                      point: _homeLocation!,
                      width: 44, height: 44,
                      child: const Icon(Icons.home,
                          color: Colors.blue, size: 44)),
                if (_workLocation != null)
                  Marker(
                      point: _workLocation!,
                      width: 44, height: 44,
                      child: const Icon(Icons.work,
                          color: Colors.orange, size: 44)),
                if (_destinationLocation != null)
                  Marker(
                      point: _destinationLocation!,
                      width: 48, height: 56,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin,
                          color: Colors.redAccent, size: 52)),
              ]),
            ],
          ),

          // Routing progress bar
          if (_isRouting)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                color: Colors.blueAccent,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
              ),
            ),

          // Floating Search Header (Top)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(32),
                  elevation: 6,
                  shadowColor: Colors.black26,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _onWhereToTapped,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: isDark ? Colors.white70 : Colors.black54, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Search here',
                              style: TextStyle(
                                fontSize: 17,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_isRouting)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.blueAccent),
                              ),
                            ),
                          // User Profile Avatar / Menu Button
                          Builder(
                            builder: (innerContext) => GestureDetector(
                              onTap: () => Scaffold.of(innerContext).openDrawer(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: isDark 
                                      ? Colors.white10 
                                      : Colors.blue.shade50,
                                  backgroundImage: _avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child: _avatarUrl == null
                                      ? Text(
                                          widget.userName.isNotEmpty
                                              ? widget.userName[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.blue.shade700),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Horizontal Shortcuts (Home, Work, etc.)
                SizedBox(
                  height: 44,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        _locationChip(
                          type: 'home',
                          icon: Icons.home_rounded,
                          label: 'Home',
                          isSet: _homeLocation != null,
                          activeColor: Colors.blue,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _locationChip(
                          type: 'work',
                          icon: Icons.work_rounded,
                          label: 'Work',
                          isSet: _workLocation != null,
                          activeColor: Colors.orange,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        // Future shortcuts can be added here easily
                        _locationChip(
                          type: 'recent',
                          icon: Icons.history_rounded,
                          label: 'Recent',
                          isSet: false, // Placeholder
                          activeColor: Colors.purple,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasRoute)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(24),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _clearRoute,
                          child: const Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.close, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Clear Route',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ETA / Distance info card
          if (_routeInfo.hasRoute)
            Positioned(
              left: 16, right: 16, bottom: 220,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.darkBackground.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _infoChip(
                      icon: Icons.straighten_rounded,
                      color: Colors.blueAccent,
                      label: _routeInfo.distanceText,
                      isDark: isDark,
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _infoChip(
                      icon: Icons.timer_rounded,
                      color: Colors.green,
                      label: _routeInfo.etaText,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

          // FABs
          Positioned(
            right: 16, bottom: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'sat_btn',
                  onPressed: _toggleSatellite,
                  backgroundColor: isDark ? primaryBgColor : Colors.white,
                  child: Icon(
                      _isSatellite ? Icons.map : Icons.satellite_alt,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'relocate_btn_main',
                  onPressed: _relocateMe,
                  backgroundColor: isDark ? primaryBgColor : Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.green),
                ),
              ],
            ),
          ),

          // Bottom bar
          Positioned(
            left: 16, right: 16, bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Good Morning, ${widget.userName}!',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppConstants.darkBackground),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppConstants.darkBackground)),
    ]);
  }

  Widget _locationChip({
    required String type,
    required IconData icon,
    required String label,
    required bool isSet,
    required Color activeColor,
    required bool isDark,
  }) {
    return Material(
      color: (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
          .withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (type == 'recent') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recent places coming soon!')),
            );
          } else {
            _handleLocationButton(type);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSet ? activeColor : (isDark ? Colors.white38 : Colors.black38), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppConstants.darkBackground,
                ),
              ),
              if (isSet)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
