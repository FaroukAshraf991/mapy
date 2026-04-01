import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.tileBg,
    required this.onTap,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color tileBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Material(
      color: tileBg,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(16),
          ),
          child: Row(
            children: [
              // Colored circle icon
              Container(
                width: context.r(42),
                height: context.r(42),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: context.sp(20),
                ),
              ),
              SizedBox(width: context.w(16)),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.sp(13),
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
                size: context.sp(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
