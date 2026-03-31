import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();
  LatLng _centerLocation =
      const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _relocateMe();
    });
  }

  Future<void> _relocateMe() async {
    try {
      final result = await LocationPermissionHelper.requestPermission();
      if (!result.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'Location error')));
        return;
      }

      if (!mounted) return;
      Position position = await Geolocator.getCurrentPosition();
      LatLng newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _centerLocation = newLoc;
      });
      _mapController.move(newLoc, 17.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Location Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLocation,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _centerLocation = position.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmTileUserAgent,
              ),
            ],
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
              onPressed: _relocateMe,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location,
                  color: Colors.green, size: context.sp(24)),
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
              onPressed: () {
                Navigator.of(context).pop(_centerLocation);
              },
              child: Text('Confirm Location',
                  style:
                      TextStyle(fontSize: context.sp(18), color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
