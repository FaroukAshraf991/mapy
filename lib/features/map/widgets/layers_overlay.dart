import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';

class LayersOverlay extends StatefulWidget {
  final MapStyle currentStyle;
  final bool isDark;
  final bool showTraffic;
  final bool showTransit;
  final bool showBiking;
  final Function(MapStyle) onStyleSelected;
  final Function(bool) onTrafficToggle;
  final Function(bool) onTransitToggle;
  final Function(bool) onBikingToggle;

  const LayersOverlay({
    super.key,
    required this.currentStyle,
    required this.isDark,
    required this.showTraffic,
    required this.showTransit,
    required this.showBiking,
    required this.onStyleSelected,
    required this.onTrafficToggle,
    required this.onTransitToggle,
    required this.onBikingToggle,
  });

  static Future<void> show({
    required BuildContext context,
    required MapStyle currentStyle,
    required bool isDark,
    required bool showTraffic,
    required bool showTransit,
    required bool showBiking,
    required Function(MapStyle) onStyleSelected,
    required Function(bool) onTrafficToggle,
    required Function(bool) onTransitToggle,
    required Function(bool) onBikingToggle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LayersOverlay(
        currentStyle: currentStyle,
        isDark: isDark,
        showTraffic: showTraffic,
        showTransit: showTransit,
        showBiking: showBiking,
        onStyleSelected: onStyleSelected,
        onTrafficToggle: onTrafficToggle,
        onTransitToggle: onTransitToggle,
        onBikingToggle: onBikingToggle,
      ),
    );
  }

  @override
  State<LayersOverlay> createState() => _LayersOverlayState();
}

class _LayersOverlayState extends State<LayersOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late bool _showTraffic;
  late bool _showTransit;
  late bool _showBiking;

  @override
  void initState() {
    super.initState();
    _showTraffic = widget.showTraffic;
    _showTransit = widget.showTransit;
    _showBiking = widget.showBiking;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDark ? Colors.white54 : Colors.black45;
    final dividerColor = widget.isDark ? Colors.white10 : Colors.black12;
    final tileBg =
        widget.isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.r(28))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(textColor, subtitleColor),
              SizedBox(height: context.h(20)),
              _buildMapTypes(textColor, subtitleColor, tileBg, dividerColor),
              SizedBox(height: context.h(16)),
              Divider(
                  color: dividerColor,
                  height: 1,
                  indent: context.w(20),
                  endIndent: context.w(20)),
              SizedBox(height: context.h(16)),
              _buildLayerToggles(textColor, subtitleColor, tileBg),
              SizedBox(
                  height:
                      context.h(24) + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: context.w(40),
      height: context.h(4),
      margin: EdgeInsets.symmetric(vertical: context.h(14)),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(context.r(2)),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subtitleColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map type',
                  style: TextStyle(
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Choose your preferred view',
                  style: TextStyle(
                    fontSize: context.sp(13),
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: textColor, size: context.sp(22)),
            tooltip: 'Close layers panel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypes(
      Color textColor, Color subtitleColor, Color tileBg, Color dividerColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Row(
        children: [
          Expanded(
              child: _buildMapTypeCard(MapStyle.street, 'Default',
                  Icons.map_rounded, tileBg, textColor, subtitleColor)),
          SizedBox(width: context.w(12)),
          Expanded(
              child: _buildMapTypeCard(
                  MapStyle.satellite,
                  'Satellite',
                  Icons.satellite_alt_rounded,
                  tileBg,
                  textColor,
                  subtitleColor)),
          SizedBox(width: context.w(12)),
          Expanded(
              child: _buildMapTypeCard(MapStyle.terrain, 'Terrain',
                  Icons.terrain_rounded, tileBg, textColor, subtitleColor)),
        ],
      ),
    );
  }

  Widget _buildMapTypeCard(MapStyle style, String label, IconData icon,
      Color tileBg, Color textColor, Color subtitleColor) {
    final isSelected = widget.currentStyle == style;

    return GestureDetector(
      onTap: () {
        widget.onStyleSelected(style);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(context.w(16)),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : tileBg,
          borderRadius: BorderRadius.circular(context.r(16)),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.blueAccent
                  : (widget.isDark ? Colors.white70 : Colors.black54),
              size: context.sp(32),
            ),
            SizedBox(height: context.h(8)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(12),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blueAccent : subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerToggles(
      Color textColor, Color subtitleColor, Color tileBg) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Column(
        children: [
          _buildToggleTile(
            icon: Icons.traffic_rounded,
            iconColor: _showTraffic ? Colors.green : Colors.grey,
            label: 'Traffic',
            subtitle: 'Real-time traffic conditions',
            value: _showTraffic,
            onChanged: (value) {
              setState(() => _showTraffic = value);
              widget.onTrafficToggle(value);
            },
            tileBg: tileBg,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          SizedBox(height: context.h(12)),
          _buildToggleTile(
            icon: Icons.directions_transit_rounded,
            iconColor: _showTransit ? Colors.purple : Colors.grey,
            label: 'Transit',
            subtitle: 'Public transport routes',
            value: _showTransit,
            onChanged: (value) {
              setState(() => _showTransit = value);
              widget.onTransitToggle(value);
            },
            tileBg: tileBg,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          SizedBox(height: context.h(12)),
          _buildToggleTile(
            icon: Icons.directions_bike_rounded,
            iconColor: _showBiking ? Colors.blue : Colors.grey,
            label: 'Biking',
            subtitle: 'Bike lanes and paths',
            value: _showBiking,
            onChanged: (value) {
              setState(() => _showBiking = value);
              widget.onBikingToggle(value);
            },
            tileBg: tileBg,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color tileBg,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(16), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: context.sp(22)),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.sp(15),
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.sp(12),
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Toggle \$label',
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: iconColor,
              activeTrackColor: iconColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
