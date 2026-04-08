import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/geocoding_service.dart';
import 'package:mapy/services/search_history_service.dart';
import 'package:mapy/features/map/widgets/search_screen_builder.dart';
import 'package:mapy/features/map/widgets/shortcuts_bar.dart';
import 'package:mapy/features/map/widgets/more_shortcuts_sheet.dart';
import 'package:mapy/features/map/screens/pick_location_screen.dart';
import 'package:mapy/features/map/screens/search_history_screen.dart';
import 'package:geolocator/geolocator.dart';

class NextWhereToScreen extends StatefulWidget {
  final String? initialQuery;
  final ll.LatLng? homeLocation;
  final ll.LatLng? workLocation;
  final List<Map<String, dynamic>> customPins;
  final List<PlaceResult> searchHistory;

  const NextWhereToScreen({
    super.key,
    this.initialQuery,
    this.homeLocation,
    this.workLocation,
    this.customPins = const [],
    this.searchHistory = const [],
  });

  @override
  State<NextWhereToScreen> createState() => _NextWhereToScreenState();
}

class _NextWhereToScreenState extends State<NextWhereToScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  Timer? _debounce;
  List<PlaceResult> _results = [];
  List<PlaceResult> _history = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isListening = false;
  Position? _currentPosition;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadHistory();
    _getCurrentLocation();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      final code = await GeocodingService.getCountryCode(pos.latitude, pos.longitude);
      if (mounted && code != null) setState(() => _countryCode = code);
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
    _speech.stop();
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
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await GeocodingService.searchPlaces(
        query,
        biasLat: _currentPosition?.latitude,
        biasLon: _currentPosition?.longitude,
        countryCodes: _countryCode,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    });
  }

  Future<void> _startVoiceSearch() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (!available || !mounted) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        // Update on every partial result for real-time feedback
        _searchController.text = result.recognizedWords;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopVoiceSearch() {
    _speech.stop();
    setState(() => _isListening = false);
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

  Future<void> _showAllHistory() async {
    final result = await Navigator.of(context).push<PlaceResult>(
      MaterialPageRoute(
        builder: (_) => SearchHistoryScreen(initialHistory: _history),
      ),
    );
    // Reload history in case the user deleted items
    await _loadHistory();
    if (result != null && mounted) {
      await _selectPlace(result);
    }
  }

  void _popWithLocation(double lat, double lon, String name) {
    Navigator.of(context).pop(<String, dynamic>{
      'lat': lat,
      'lon': lon,
      'name': name,
    });
  }

  void _popWithAction(String action, ll.LatLng location) {
    Navigator.of(context).pop(<String, dynamic>{
      'action': action,
      'lat': location.latitude,
      'lon': location.longitude,
    });
  }

  Future<void> _handleHomeTap() async {
    final home = widget.homeLocation;
    if (home != null) {
      _popWithLocation(home.latitude, home.longitude, 'Home');
      return;
    }
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => const PickLocationScreen(title: 'Set Home Location'),
      ),
    );
    if (picked != null && mounted) {
      _popWithAction('setHome', picked);
    }
  }

  Future<void> _handleWorkTap() async {
    final work = widget.workLocation;
    if (work != null) {
      _popWithLocation(work.latitude, work.longitude, 'Work');
      return;
    }
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => const PickLocationScreen(title: 'Set Work Location'),
      ),
    );
    if (picked != null && mounted) {
      _popWithAction('setWork', picked);
    }
  }

  void _handleMoreTap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    MoreShortcutsSheet.show(
      context: context,
      isDark: isDark,
      customPins: widget.customPins,
      onPinTap: (pin) {
        Navigator.of(context).pop();
        _popWithLocation(
          pin['lat'] as double,
          pin['lon'] as double,
          pin['label'] as String,
        );
      },
      onPinLongPress: (_) {},
      onAddTap: () {
        Navigator.of(context).pop();
        _handleAddPin();
      },
    );
  }

  Future<void> _handleAddPin() async {
    final label = await _showPinNameDialog();
    if (label == null || label.isEmpty || !mounted) return;

    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(title: label),
      ),
    );
    if (picked == null || !mounted) return;

    Navigator.of(context).pop(<String, dynamic>{
      'action': 'addPin',
      'lat': picked.latitude,
      'lon': picked.longitude,
      'name': label,
    });
  }

  Future<String?> _showPinNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this place'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Gym, Coffee shop...'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _SearchAppBar(
        isDark: isDark,
        bgColor: bgColor,
        controller: _searchController,
        autofocus: widget.initialQuery == null,
        isListening: _isListening,
        onMicTap: _isListening ? _stopVoiceSearch : _startVoiceSearch,
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(8),
            ),
            child: ShortcutsBar(
              isDark: isDark,
              hasHome: widget.homeLocation != null,
              hasWork: widget.workLocation != null,
              customPins: widget.customPins,
              onHomeTap: _handleHomeTap,
              onWorkTap: _handleWorkTap,
              onCustomPinTap: (pin) => _popWithLocation(
                pin['lat'] as double,
                pin['lon'] as double,
                pin['label'] as String,
              ),
              onCustomPinLongPress: (_) {},
              onAddTap: _handleMoreTap,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          Expanded(
            child: SearchScreenBuilder.buildBody(
              context: context,
              isLoading: _isLoading,
              hasSearched: _hasSearched,
              results: _results,
              history: _history,
              isDark: isDark,
              onShowAllHistory: _showAllHistory,
              onSelectPlace: _selectPlace,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final Color bgColor;
  final TextEditingController controller;
  final bool autofocus;
  final bool isListening;
  final VoidCallback onMicTap;

  const _SearchAppBar({
    required this.isDark,
    required this.bgColor,
    required this.controller,
    required this.autofocus,
    required this.isListening,
    required this.onMicTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black45;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      foregroundColor: textColor,
      titleSpacing: 0,
      title: TextField(
        controller: controller,
        autofocus: autofocus,
        style: TextStyle(color: textColor, fontSize: context.sp(17)),
        cursorColor: Colors.teal,
        decoration: InputDecoration(
          hintText: 'Search here',
          hintStyle: TextStyle(color: hintColor, fontSize: context.sp(17)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isNotEmpty) {
              return IconButton(
                icon: Icon(Icons.close, color: hintColor),
                onPressed: () => controller.clear(),
              );
            }
            return _MicButton(
              isListening: isListening,
              hintColor: hintColor,
              onTap: onMicTap,
            );
          },
        ),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final Color hintColor;
  final VoidCallback onTap;

  const _MicButton({
    required this.isListening,
    required this.hintColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isListening
          ? Icon(Icons.mic_rounded, color: Colors.red)
          : Icon(Icons.mic_none_rounded, color: hintColor),
      onPressed: onTap,
      tooltip: isListening ? 'Stop listening' : 'Voice search',
    );
  }
}
