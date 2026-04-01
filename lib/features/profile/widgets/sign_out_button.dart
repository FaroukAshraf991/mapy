import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.surfaceColor,
    required this.onSignOut,
  });

  final Color surfaceColor;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(35)),
      leading: Container(
        width: context.r(42),
        height: context.r(42),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: surfaceColor,
        ),
        child: Icon(
          Icons.logout_rounded,
          color: const Color(0xFFE05454),
          size: context.sp(20),
        ),
      ),
      title: Text(
        'Sign out',
        style: TextStyle(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE05454),
        ),
      ),
      onTap: onSignOut,
    );
  }
}
