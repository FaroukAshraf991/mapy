import 'package:flutter/material.dart';

/// Floating control buttons for the map (GPS relocate, Layers menu).
class MapControlsOverlay extends StatelessWidget {
  final bool isNavigating;
  final VoidCallback onRelocate;
  final VoidCallback onLayers;
  final bool isDark;

  const MapControlsOverlay({
    super.key,
    required this.isNavigating,
    required this.onRelocate,
    required this.onLayers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _floatingButton(
          icon: isNavigating ? Icons.navigation_rounded : Icons.my_location_rounded,
          onTap: onRelocate,
          color: isNavigating ? Colors.blueAccent : (isDark ? Colors.white : Colors.black87),
          bgColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        const SizedBox(height: 12),
        _floatingButton(
          icon: Icons.layers_rounded,
          onTap: onLayers,
          color: isDark ? Colors.white70 : Colors.black54,
          bgColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
      ],
    );
  }

  Widget _floatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
