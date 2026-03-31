import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool isDark;
  final bool showError;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    required this.isDark,
    this.showError = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor =
        widget.isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54;
    final iconColor =
        widget.isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87;
    final fillColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.8);

    return TextField(
      controller: widget.controller,
      style: TextStyle(color: textColor, fontSize: context.sp(15)),
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: hintColor, fontSize: context.sp(15)),
        prefixIcon: Icon(widget.icon, color: iconColor, size: context.sp(22)),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                  size: context.sp(22),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(16)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(16)),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(16)),
            borderSide: BorderSide(
                color: widget.showError
                    ? Colors.red
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey.shade300),
                width: widget.showError ? 2 : 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(16)),
            borderSide: BorderSide(
                color: widget.showError
                    ? Colors.red
                    : (widget.isDark ? Colors.white : Colors.blueAccent),
                width: 2)),
      ),
    );
  }
}
