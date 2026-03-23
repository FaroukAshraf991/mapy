import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/search_history_service.dart';

/// Full-featured geocoding search screen with live results and search history.
/// Returns the chosen [LatLng] via [Navigator.pop] when a place is selected.
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.getHistory();
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
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    });
  }

  Future<void> _selectPlace(PlaceResult place) async {
    await SearchHistoryService.addToHistory(place);
    if (!mounted) return;
    Navigator.of(context).pop(LatLng(place.lat, place.lon));
  }

  Future<void> _clearHistory() async {
    await SearchHistoryService.clearHistory();
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
          style: TextStyle(color: textColor, fontSize: 17),
          cursorColor: Colors.blueAccent,
          decoration: InputDecoration(
            hintText: 'Search for a place...',
            hintStyle: TextStyle(color: hintColor),
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
          Divider(height: 1, thickness: 1,
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

    // Show search results
    if (_hasSearched) {
      if (_results.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_off_rounded, size: 64, color: hintColor),
            const SizedBox(height: 16),
            Text('No places found.',
                style: TextStyle(fontSize: 17, color: hintColor)),
            const SizedBox(height: 8),
            Text('Try a different search term.',
                style: TextStyle(
                    fontSize: 14,
                    color: hintColor.withValues(alpha: 0.7))),
          ]),
        );
      }
      return _buildResultsList(cardColor, textColor, hintColor);
    }

    // Show history or empty state
    if (_history.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 18, color: hintColor),
                const SizedBox(width: 8),
                Text('Recent',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hintColor)),
                const Spacer(),
                TextButton(
                  onPressed: _clearHistory,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4)),
                  child: const Text('Clear',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              itemCount: _history.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 6),
              itemBuilder: (context, index) =>
                  _placeCard(_history[index], cardColor, textColor,
                      hintColor, isHistory: true),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_rounded, size: 72, color: hintColor),
        const SizedBox(height: 16),
        Text('Where do you want to go?',
            style: TextStyle(
                fontSize: 18,
                color: hintColor,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Type an address, city, or landmark.',
            style: TextStyle(
                fontSize: 14,
                color: hintColor.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _buildResultsList(
      Color cardColor, Color textColor, Color hintColor) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectPlace(place),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (isHistory ? Colors.grey : Colors.redAccent)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHistory
                    ? Icons.history_rounded
                    : Icons.location_pin,
                color: isHistory ? Colors.grey : Colors.redAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  if (place.address.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.55))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: textColor.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }
}
