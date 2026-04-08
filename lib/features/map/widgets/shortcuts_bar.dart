import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// Google Maps–style shortcuts row: Home · Work · More
class ShortcutsBar extends StatelessWidget {
  final bool isDark;
  final bool hasHome;
  final bool hasWork;
  final List<Map<String, dynamic>> customPins;
  final VoidCallback onHomeTap;
  final VoidCallback onWorkTap;
  final Function(Map<String, dynamic>) onCustomPinTap;
  final Function(Map<String, dynamic>) onCustomPinLongPress;
  final VoidCallback onAddTap;

  const ShortcutsBar({
    super.key,
    required this.isDark,
    required this.hasHome,
    required this.hasWork,
    required this.customPins,
    required this.onHomeTap,
    required this.onWorkTap,
    required this.onCustomPinTap,
    required this.onCustomPinLongPress,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutPill(
            isDark: isDark,
            icon: Icons.home_rounded,
            label: 'Home',
            subtitle: hasHome ? 'Saved' : 'Set location',
            onTap: onHomeTap,
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: _ShortcutPill(
            isDark: isDark,
            icon: Icons.work_rounded,
            label: 'Work',
            subtitle: hasWork ? 'Saved' : 'Set location',
            onTap: onWorkTap,
          ),
        ),
        SizedBox(width: context.w(8)),
        _MoreButton(isDark: isDark, onTap: onAddTap),
      ],
    );
  }
}

// ─── Pill button (Home / Work) ────────────────────────────────────────────────

class _ShortcutPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ShortcutPill({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(10),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(36),
                height: context.w(36),
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: context.sp(18), color: textColor),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.sp(13),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── More button ──────────────────────────────────────────────────────────────

class _MoreButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _MoreButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(36),
                height: context.w(36),
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(Icons.more_horiz_rounded,
                    size: context.sp(18), color: textColor),
              ),
              SizedBox(width: context.w(6)),
              Text(
                'More',
                style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
