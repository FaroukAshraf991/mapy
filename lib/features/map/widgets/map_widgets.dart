import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/map/screens/main_map_screen.dart'; // To use MapStyle enum

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
    return Material(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(32),
      elevation: 6,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSearchTap,
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
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
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
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    final bgColor = (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
        .withValues(alpha: 0.9);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color:
                      isSet ? activeColor : (isDark ? Colors.white38 : Colors.black38),
                  size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (isSet && type != 'custom')
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
    return Material(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _styleItem(MapStyle.street, 'Default', Icons.map_rounded),
              _styleItem(MapStyle.satellite, 'Satellite', Icons.satellite_alt_rounded),
              _styleItem(MapStyle.terrain, 'Terrain', Icons.terrain_rounded),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an individual style selection item (Icon + Label).
  Widget _styleItem(MapStyle style, String label, IconData icon) {
    final isSelected = currentStyle == style;

    return GestureDetector(
      onTap: () => onStyleSelected(style),
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
    final bgColor = (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
        .withValues(alpha: 0.9);
    final foregroundColor = isDark ? Colors.white70 : Colors.black54;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: foregroundColor, size: 20),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
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
  
  /// The color of the icon for visual distinction.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
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



