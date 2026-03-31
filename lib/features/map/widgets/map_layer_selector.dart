import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/models/map_enums.dart';

class MapLayerSelector extends StatelessWidget {
  final MapStyle currentStyle;
  final bool isDark;
  final bool showTraffic;
  final Function(MapStyle) onStyleSelected;
  final Function(bool) onTrafficToggle;

  const MapLayerSelector({
    super.key,
    required this.currentStyle,
    required this.isDark,
    required this.showTraffic,
    required this.onStyleSelected,
    required this.onTrafficToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(24), vertical: context.h(32)),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.modalBackground : Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(24))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Map Style',
              style: TextStyle(
                  fontSize: context.sp(20),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          SizedBox(height: context.h(24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _styleItem(
                  context, MapStyle.street, 'Default', Icons.map_rounded),
              _styleItem(context, MapStyle.satellite, 'Satellite',
                  Icons.satellite_alt_rounded),
            ],
          ),
          SizedBox(height: context.h(24)),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          SizedBox(height: context.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.traffic_rounded,
                    color: showTraffic ? Colors.green : Colors.grey,
                    size: context.sp(24),
                  ),
                  SizedBox(width: context.w(12)),
                  Text('Traffic Layer',
                      style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              Switch(
                value: showTraffic,
                onChanged: onTrafficToggle,
                activeTrackColor: Colors.green.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  return showTraffic ? Colors.green : Colors.grey;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styleItem(
      BuildContext context, MapStyle style, String label, IconData icon) {
    final isSelected = currentStyle == style;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onStyleSelected(style);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon,
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? Colors.white70 : Colors.black54),
                size: context.sp(32)),
          ),
          SizedBox(height: context.h(8)),
          Text(label,
              style: TextStyle(
                fontSize: context.sp(13),
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
