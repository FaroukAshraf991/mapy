import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

class MapInfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
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
    final greyColor = isDark ? Colors.white70 : Colors.black54;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: greyColor, size: context.sp(22)),
        SizedBox(width: context.w(8)),
        Text(
          label,
          style: TextStyle(
            fontSize: context.sp(17),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppConstants.darkBackground,
          ),
        ),
      ],
    );
  }
}
