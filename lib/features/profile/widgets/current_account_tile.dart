import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/switcher_avatar.dart';

class CurrentAccountTile extends StatelessWidget {
  const CurrentAccountTile({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtitleColor,
    required this.name,
    required this.email,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtitleColor;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(10),
        ),
        leading: SwitcherAvatar(surfaceColor: surfaceColor, initial: initial),
        title: Text(
          name.isNotEmpty ? name : 'Your Name',
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            fontSize: context.sp(12),
            color: subtitleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          width: context.r(28),
          height: context.r(28),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4285F4),
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: context.sp(16),
          ),
        ),
      ),
    );
  }
}
