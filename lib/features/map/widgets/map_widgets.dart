import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/map/screens/main_map_screen.dart'; // To use MapStyle enum
import 'package:mapy/models/place_result.dart';

// ── WIDGETS ──────────────────────────────────────────────────────────────────

/// A reusable search bar with a profile avatar button on the right.
/// Used at the top of the map screen to trigger location searches and access
/// the user's profile drawer.
class MapSearchBar extends StatelessWidget {
  /// Whether the app is currently in dark mode.
  final bool isDark;
  
  /// Whether a route is currently being calculated (shows a progress indicator).
  final bool isRouting;
  
  /// The URL of the user's profile picture from Supabase.
  final String? avatarUrl;
  
  /// Callback triggered when the main search area is tapped.
  final VoidCallback onSearchTap;
  
  /// Callback triggered when the profile avatar icon is tapped.
  final VoidCallback onAvatarTap;

  const MapSearchBar({
    super.key,
    required this.isDark,
    required this.isRouting,
    required this.avatarUrl,
    required this.onSearchTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(32),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.search,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Search here',
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isRouting)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blueAccent),
                      ),
                    ),
                  Hero(
                    tag: 'profileAvatar',
                    child: GestureDetector(
                      onTap: onAvatarTap,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isDark)
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          backgroundImage:
                              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
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
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// A specialized chip for the horizontal shortcuts list (Recent, Home, Work, etc.).
/// Features individual styling based on the shortcut type and "is set" status.
class LocationChip extends StatelessWidget {
  /// The type identifier (e.g., 'home', 'work', 'recent', 'custom').
  final String type;
  
  /// The icon to display on the left.
  final IconData icon;
  
  /// The display label.
  final String label;
  
  /// Whether the location has been set in the profile.
  final bool isSet;
  
  /// The color to use when the location is set.
  final Color activeColor;
  
  /// Whether the app is in dark mode.
  final bool isDark;
  
  /// Primary tap callback.
  final VoidCallback onTap;
  
  /// Long press callback (usually for deletion).
  final VoidCallback? onLongPress;
  
  /// Optional trailing icon (e.g., dropdown arrow).
  final IconData? trailingIcon;

  const LocationChip({
    super.key,
    required this.type,
    required this.icon,
    required this.label,
    required this.isSet,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSet 
                    ? activeColor.withValues(alpha: 0.4) 
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: isSet ? activeColor : (isDark ? Colors.white38 : Colors.black38),
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(trailingIcon,
                        color: isSet ? activeColor : (isDark ? Colors.white38 : Colors.black38),
                        size: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// A circular floating action button styled for the map UI.
/// Used for "Relocate Me" and "Layers" toggle.
class MapActionButton extends StatelessWidget {
  /// The icon to display.
  final IconData icon;
  
  /// Tap callback.
  final VoidCallback onPressed;
  
  /// The color of the icon.
  final Color color;
  
  /// Whether the app is in dark mode.
  final bool isDark;

  const MapActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, color: color, size: 24),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// The content for the Map Style selection bottom sheet.
/// Allows the user to toggle between Default, Satellite, and Terrain views.
class MapLayerSelector extends StatelessWidget {
  /// The currently active map style.
  final MapStyle currentStyle;
  
  /// Whether the app is in dark mode.
  final bool isDark;
  
  /// Callback triggered when a new style is selected.
  final Function(MapStyle) onStyleSelected;

  const MapLayerSelector({
    super.key,
    required this.currentStyle,
    required this.isDark,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Map Style',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _styleItem(context, MapStyle.street, 'Default', Icons.map_rounded),
              _styleItem(context, MapStyle.satellite, 'Satellite', Icons.satellite_alt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an individual style selection item (Icon + Label).
  Widget _styleItem(BuildContext context, MapStyle style, String label, IconData icon) {
    final isSelected = currentStyle == style;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onStyleSelected(style);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.1)
                  : (isDark
                       ? Colors.white.withValues(alpha: 0.05)
                       : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon,
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? Colors.white70 : Colors.black54),
                size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? Colors.white70 : Colors.black54),
              )),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// The "Add" button used at the end of the shortcut list to define a new favorite.
class AddShortcutButton extends StatelessWidget {
  /// Whether the app is in dark mode.
  final bool isDark;
  
  /// Tap callback.
  final VoidCallback onTap;

  const AddShortcutButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: foregroundColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// A specialized chip for displaying route information (ETA and Distance).
/// Used in the floating card that appears when a route is destination is set.
class MapInfoChip extends StatelessWidget {
  /// The icon representing the metric (e.g., straight for distance, timer for ETA).
  final IconData icon;
  
  /// The color of the icon for visual distinction (defaulting to grey for modern view).
  final Color color;
  
  /// The display text (e.g., "12 min", "5.4 km").
  final String label;
  
  /// Whether the app is in dark mode.
  final bool isDark;

  const MapInfoChip({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Overriding the provided color with a premium grey scale as per modern design request
    final greyColor = isDark ? Colors.white70 : Colors.black54;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: greyColor, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppConstants.darkBackground,
          ),
        ),
      ],
    );
  }
}



// ──────────────────────────────────────────────────────────────────────────────

/// A premium glass bottom sheet that displays the user's search history.
class RecentsBottomSheet extends StatelessWidget {
  final List<PlaceResult> history;
  final bool isDark;
  final Function(PlaceResult) onSelect;
  final VoidCallback onClear;

  const RecentsBottomSheet({
    super.key,
    required this.history,
    required this.isDark,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark 
        ? Colors.black.withValues(alpha: 0.85) 
        : Colors.white.withValues(alpha: 0.9);
        
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Locations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppConstants.darkBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton(
                        onPressed: onClear,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, 
                          size: 48, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'No recent searches',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final place = history[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded, color: Colors.purple, size: 20),
                        ),
                        title: Text(
                          place.shortName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppConstants.darkBackground,
                          ),
                        ),
                        subtitle: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => onSelect(place),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 32), // Safe area bottom
            ],
          ),
        ),
      ),
    );
  }
}
