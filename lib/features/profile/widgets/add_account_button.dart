import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class AddAccountButton extends StatelessWidget {
  const AddAccountButton({
    super.key,
    required this.surfaceColor,
    required this.textColor,
    required this.onAddAccount,
  });

  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onAddAccount;

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
          Icons.person_add_rounded,
          color: const Color(0xFF4285F4),
          size: context.sp(20),
        ),
      ),
      title: Text(
        'Add another account',
        style: TextStyle(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      onTap: onAddAccount,
    );
  }
}
