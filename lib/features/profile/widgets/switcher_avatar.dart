import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class SwitcherAvatar extends StatelessWidget {
  const SwitcherAvatar({
    super.key,
    required this.surfaceColor,
    required this.initial,
  });

  final Color surfaceColor;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: context.r(48),
          height: context.r(48),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF4285F4),
                Color(0xFF34A853),
                Color(0xFFFBBC05),
                Color(0xFFEA4335),
                Color(0xFF4285F4),
              ],
            ),
          ),
        ),
        Positioned(
          top: context.r(2),
          left: context.r(2),
          child: Container(
            width: context.r(44),
            height: context.r(44),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
            ),
          ),
        ),
        Positioned(
          top: context.r(4),
          left: context.r(4),
          child: CircleAvatar(
            radius: context.r(20),
            backgroundColor: const Color(0xFF5B8DEF),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
