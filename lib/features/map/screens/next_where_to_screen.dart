import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/search_history_service.dart';
import 'package:geolocator/geolocator.dart';

class NextWhereToScreen extends StatefulWidget {
  const NextWhereToScreen({super.key});

  @override
  State<NextWhereToScreen> createState() => _NextWhereToScreenState();
}

class _NextWhereToScreenState extends State<NextWhereToScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<PlaceResult> _results = [];
  List<PlaceResult> _history = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadHistory();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {
      // Location fetch failed; search will proceed without bias
    }
  }

  Future<void> _loadHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final history = await SearchHistoryService.getHistory(uid);
    if (!mounted) return;
    setState(() => _history = history);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text;

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await GeocodingService.searchPlaces(
        query,
        biasLat: _currentPosition?.latitude,
        biasLon: _currentPosition?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    });
  }

  Future<void> _selectPlace(PlaceResult place) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await SearchHistoryService.addToHistory(uid, place);
    }
    if (!mounted) return;
    Navigator.of(context).pop(LatLng(place.lat, place.lon));
  }

  Future<void> _clearHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await SearchHistoryService.clearHistory(uid);
    }
    if (!mounted) return;
    setState(() => _history = []);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.9);
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    final hintColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: context.sp(17)),
          cursorColor: Colors.blueAccent,
          decoration: InputDecoration(
            hintText: 'Search for a place...',
            hintStyle: TextStyle(color: hintColor, fontSize: context.sp(17)),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: hintColor),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white12 : Colors.black12),
          Expanded(
            child: _buildBody(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color hintColor,
  }) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    if (_hasSearched) {
      if (_results.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_off_rounded,
                size: context.sp(64), color: hintColor),
            SizedBox(height: context.h(16)),
            Text('No places found.',
                style: TextStyle(fontSize: context.sp(17), color: hintColor)),
            SizedBox(height: context.h(8)),
            Text('Try a different search term.',
                style: TextStyle(
                    fontSize: context.sp(14),
                    color: hintColor.withValues(alpha: 0.7))),
          ]),
        );
      }
      return _buildResultsList(cardColor, textColor, hintColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPoiCategories(isDark, hintColor),
        if (_history.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.w(20), context.h(16), context.w(12), context.h(8)),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: context.sp(18), color: hintColor),
                SizedBox(width: context.w(8)),
                Text('Recent',
                    style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: hintColor)),
                const Spacer(),
                TextButton(
                  onPressed: _clearHistory,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(12), vertical: context.h(4))),
                  child:
                      Text('Clear', style: TextStyle(fontSize: context.sp(13))),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(16), vertical: context.h(4)),
              itemCount: _history.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: context.h(6)),
              itemBuilder: (context, index) => _placeCard(
                  _history[index], cardColor, textColor, hintColor,
                  isHistory: true),
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_rounded,
                    size: context.sp(72), color: hintColor),
                SizedBox(height: context.h(16)),
                Text('Where do you want to go?',
                    style: TextStyle(
                        fontSize: context.sp(18),
                        color: hintColor,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: context.h(8)),
                Text('Search for a place or select\na category above',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.sp(14),
                        color: hintColor.withValues(alpha: 0.7))),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPoiCategories(bool isDark, Color hintColor) {
    final poiCategories = [
      {
        'icon': Icons.restaurant_rounded,
        'label': 'Restaurant',
        'query': 'restaurant'
      },
      {
        'icon': Icons.local_gas_station_rounded,
        'label': 'Gas Station',
        'query': 'gas station'
      },
      {
        'icon': Icons.local_parking_rounded,
        'label': 'Parking',
        'query': 'parking'
      },
      {'icon': Icons.hotel_rounded, 'label': 'Hotel', 'query': 'hotel'},
      {
        'icon': Icons.shopping_bag_rounded,
        'label': 'Shopping',
        'query': 'shopping mall'
      },
      {
        'icon': Icons.local_hospital_rounded,
        'label': 'Hospital',
        'query': 'hospital'
      },
    ];

    return SizedBox(
      height: context.h(115),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(12)),
        itemCount: poiCategories.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
        itemBuilder: (context, index) {
          final category = poiCategories[index];
          return GestureDetector(
            onTap: () {
              _searchController.text = category['query'] as String;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(14)),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.blueAccent,
                    size: context.sp(24),
                  ),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  category['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(11),
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(Color cardColor, Color textColor, Color hintColor) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
          vertical: context.h(12), horizontal: context.w(16)),
      itemCount: _results.length,
      separatorBuilder: (context, index) => SizedBox(height: context.h(8)),
      itemBuilder: (context, index) =>
          _placeCard(_results[index], cardColor, textColor, hintColor),
    );
  }

  Widget _placeCard(
    PlaceResult place,
    Color cardColor,
    Color textColor,
    Color hintColor, {
    bool isHistory = false,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(context.r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(16)),
        onTap: () => _selectPlace(place),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.w(16), vertical: context.h(14)),
          child: Row(children: [
            Container(
              width: context.w(44),
              height: context.h(44),
              decoration: BoxDecoration(
                color: (isHistory ? Colors.grey : Colors.redAccent)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHistory ? Icons.history_rounded : Icons.location_pin,
                color: isHistory ? Colors.grey : Colors.redAccent,
                size: context.sp(22),
              ),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  if (place.address.isNotEmpty) ...[
                    SizedBox(height: context.h(3)),
                    Text(place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.sp(13),
                            color: textColor.withValues(alpha: 0.55))),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            Icon(Icons.arrow_forward_ios_rounded,
                size: context.sp(14), color: textColor.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }
}
