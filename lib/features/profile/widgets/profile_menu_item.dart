import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isDark ? Colors.white70 : Colors.black54);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(24)),
      leading: Icon(icon, color: effectiveColor, size: context.sp(24)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(15),
          fontWeight: FontWeight.w600,
          color: color ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
    );
  }
}
