import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// A styled card container for settings groups
class SettingsCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const SettingsCard({
    super.key,
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.r(20)),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(20)),
        child: child,
      ),
    );
  }
}
