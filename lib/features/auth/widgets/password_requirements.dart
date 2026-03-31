import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;
  final bool isDark;

  const PasswordRequirements({
    super.key,
    required this.password,
    required this.isDark,
  });

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => password.contains(RegExp(r'[!@#$%^&*]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItem(context, 'At least 8 characters', _hasMinLength),
        _buildItem(context, 'One uppercase letter (A-Z)', _hasUppercase),
        _buildItem(context, 'One number (0-9)', _hasNumber),
        _buildItem(context, 'One special character (!@#\$%^&*)', _hasSpecial),
      ],
    );
  }

  Widget _buildItem(BuildContext context, String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(2)),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: context.sp(14),
            color:
                isMet ? Colors.green : (isDark ? Colors.white38 : Colors.grey),
          ),
          SizedBox(width: context.w(8)),
          Text(
            text,
            style: TextStyle(
              fontSize: context.sp(12),
              color: isMet
                  ? Colors.green
                  : (isDark ? Colors.white54 : Colors.grey.shade600),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
