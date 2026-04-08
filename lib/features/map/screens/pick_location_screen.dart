import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/location_permission_helper.dart';
import 'package:mapy/core/utils/responsive.dart';

class PickLocationScreen extends StatefulWidget {
  final String title;

  const PickLocationScreen({super.key, required this.title});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  MapLibreMapController? _mapController;

  // Default fallback; real center is read from controller.cameraPosition on confirm
  LatLng _defaultLocation = const LatLng(
    AppConstants.defaultLat,
    AppConstants.defaultLng,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _relocateMe());
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _relocateMe() async {
    try {
      final result = await LocationPermissionHelper.requestPermission();
      if (!result.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Location error')),
        );
        return;
      }

      if (!mounted) return;
      final position = await Geolocator.getCurrentPosition();
      final newTarget = LatLng(position.latitude, position.longitude);
      setState(() => _defaultLocation = newTarget);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newTarget, 17.0),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location Error: $e')),
      );
    }
  }

  void _confirmLocation() {
    final target = _mapController?.cameraPosition?.target ?? _defaultLocation;
    Navigator.of(context).pop(
      ll.LatLng(target.latitude, target.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleString =
        isDark ? AppConstants.darkStyleUrl : AppConstants.osmStyleUrl;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          Semantics(
            label: 'Map for picking location. Drag to move, pinch to zoom.',
            child: MapLibreMap(
              styleString: styleString,
              initialCameraPosition: CameraPosition(
                target: _defaultLocation,
                zoom: 15.0,
              ),
              onMapCreated: _onMapCreated,
              trackCameraPosition: true,
              myLocationEnabled: false,
              compassEnabled: false,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.h(40)),
              child: Icon(
                Icons.location_on,
                size: context.sp(40),
                color: Colors.red,
              ),
            ),
          ),
          Positioned(
            bottom: context.h(110),
            right: context.w(20),
            child: FloatingActionButton(
              heroTag: 'relocate_btn_pick',
              tooltip: 'My location',
              onPressed: _relocateMe,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: Colors.green,
                size: context.sp(24),
              ),
            ),
          ),
          Positioned(
            bottom: context.h(30),
            left: context.w(20),
            right: context.w(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.h(16)),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              onPressed: _confirmLocation,
              child: Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: context.sp(18),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
