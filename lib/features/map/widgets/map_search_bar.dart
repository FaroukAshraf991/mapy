import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class MapSearchBar extends StatelessWidget {
  final bool isDark;
  final bool isRouting;
  final String userName;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;

  const MapSearchBar({
    super.key,
    required this.isDark,
    required this.isRouting,
    required this.userName,
    required this.onSearchTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(32)),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.1),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(10)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(12), vertical: context.h(8)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(context.r(32)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(context.r(32)),
              child: Row(
                children: [
                  SizedBox(width: context.w(8)),
                  Image.asset(
                      'assets/icon/Transparent Ico (1).png',
                      width: context.sp(28),
                      height: context.sp(28),
                    ),
                  SizedBox(width: context.w(14)),
                  Expanded(
                    child: Text(
                      'Search here',
                      style: TextStyle(
                        fontSize: context.sp(17),
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isRouting)
                    Padding(
                      padding: EdgeInsets.only(right: context.w(12)),
                      child: SizedBox(
                        width: context.w(20),
                        height: context.h(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blueAccent),
                      ),
                    ),
                  Hero(
                    tag: 'profileAvatar',
                    child: GestureDetector(
                      onTap: onAvatarTap,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isDark)
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                                blurRadius: context.w(8),
                                spreadRadius: context.w(1),
                              ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: context.r(18),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
