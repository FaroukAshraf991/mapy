import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/services/trip_history_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<TripRecord> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await TripHistoryService.getTripHistory();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await TripHistoryService.clearTripHistory();
    setState(() => _trips = []);
  }

  Future<void> _exportGpx(TripRecord trip) async {
    final points = trip.waypoints.isNotEmpty
        ? trip.waypoints.map((w) => ll.LatLng(w['lat']!, w['lng']!)).toList()
        : [trip.destination];

    final gpx = TripHistoryService.generateGpx(points, trip.destinationName);

    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/${trip.destinationName.replaceAll(' ', '_')}.gpx');
    await file.writeAsString(gpx);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Trip to ${trip.destinationName}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Trip History',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: context.sp(18))),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_trips.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _showClearDialog(isDark),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? _buildEmptyState(isDark)
              : _buildTripList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: context.sp(64),
              color: isDark ? Colors.white38 : Colors.black38),
          SizedBox(height: context.h(16)),
          Text('No trips yet',
              style: TextStyle(
                  fontSize: context.sp(18),
                  color: isDark ? Colors.white54 : Colors.black45)),
          SizedBox(height: context.h(8)),
          Text('Your trip history will appear here',
              style: TextStyle(
                  fontSize: context.sp(14),
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildTripList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(context.w(16)),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip, isDark);
      },
    );
  }

  Widget _buildTripCard(TripRecord trip, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.w(16)),
        leading: Container(
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_car_rounded, color: Colors.blueAccent),
        ),
        title: Text(
          trip.destinationName,
          style:
              TextStyle(fontWeight: FontWeight.w600, fontSize: context.sp(16)),
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.h(4)),
            Text('${trip.distanceText} • ${trip.durationText}',
                style: TextStyle(fontSize: context.sp(13))),
            Text(
              _formatDate(trip.startTime),
              style: TextStyle(
                  fontSize: context.sp(12),
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert,
              color: isDark ? Colors.white54 : Colors.black38),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.share_rounded, size: context.sp(20)),
                  SizedBox(width: context.w(8)),
                  Text('Export GPX'),
                ],
              ),
              onTap: () => _exportGpx(trip),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: context.sp(20), color: Colors.redAccent),
                  SizedBox(width: context.w(8)),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
              onTap: () => TripHistoryService.deleteTrip(trip.id)
                  .then((_) => _loadTrips()),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showClearDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will delete all your trip history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            child:
                const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
