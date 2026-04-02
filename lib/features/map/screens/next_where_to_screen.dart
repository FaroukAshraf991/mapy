import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/search_history_service.dart';
import 'package:mapy/features/map/widgets/search_screen_builder.dart';
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
              const LocationSettings(accuracy: LocationAccuracy.medium));
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
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
      final results = await GeocodingService.searchPlaces(query,
          biasLat: _currentPosition?.latitude,
          biasLon: _currentPosition?.longitude);
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
    if (uid != null) await SearchHistoryService.addToHistory(uid, place);
    if (!mounted) return;
    Navigator.of(context).pop(<String, dynamic>{
      'lat': place.lat,
      'lon': place.lon,
      'name': place.shortName,
    });
  }

  Future<void> _clearHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) await SearchHistoryService.clearHistory(uid);
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
                onPressed: () => _searchController.clear()),
        ],
      ),
      body: Column(
        children: [
          Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white12 : Colors.black12),
          Expanded(
            child: SearchScreenBuilder.buildBody(
              context: context,
              isLoading: _isLoading,
              hasSearched: _hasSearched,
              results: _results,
              history: _history,
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
              isDark: isDark,
              onClearHistory: _clearHistory,
              onSelectPlace: _selectPlace,
              onCategoryTap: (query) => _searchController.text = query,
            ),
          ),
        ],
      ),
    );
  }
}
