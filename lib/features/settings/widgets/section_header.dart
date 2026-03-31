import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// A styled section header for settings groups
class SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: context.w(8), bottom: context.h(8)),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: context.sp(12),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }
}
