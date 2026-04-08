import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final bool isDark;
  const ProfileSectionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.iconColor,
      required this.children,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    return Container(
      padding: EdgeInsets.all(context.w(24)),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(context.r(24)),
          border: Border.all(color: borderColor, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              width: context.w(40),
              height: context.h(40),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: context.sp(20))),
          SizedBox(width: context.w(14)),
          Text(title,
              style: TextStyle(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ]),
        SizedBox(height: context.h(20)),
        ...children,
      ]),
    );
  }
}

class ProfileTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark, isPassword, showError;
  final TextInputType? keyboardType;
  const ProfileTextField(
      {super.key,
      required this.controller,
      required this.hint,
      required this.icon,
      required this.isDark,
      this.isPassword = false,
      this.keyboardType,
      this.showError = false});

  @override
  State<ProfileTextField> createState() => _ProfileTextFieldState();
}

class _ProfileTextFieldState extends State<ProfileTextField> {
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
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade50;
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
                tooltip: _obscureText ? 'Show password' : 'Hide password',
                icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
                    size: context.sp(22)),
                onPressed: () => setState(() => _obscureText = !_obscureText))
            : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(16)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(14)),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(14)),
            borderSide: BorderSide(
                color: widget.showError
                    ? Colors.red
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300),
                width: widget.showError ? 2 : 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(14)),
            borderSide: BorderSide(
                color: widget.showError
                    ? Colors.red
                    : (widget.isDark ? Colors.white : Colors.blueAccent),
                width: 2)),
      ),
    );
  }
}

class ProfileActionButton extends StatelessWidget {
  final String label;
  final bool isLoading, isDark, isDestructive;
  final VoidCallback onPressed;
  const ProfileActionButton(
      {super.key,
      required this.label,
      required this.isLoading,
      required this.onPressed,
      required this.isDark,
      this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final bg = isDestructive
        ? Colors.redAccent
        : (isDark ? Colors.white : AppConstants.darkBackground);
    final fg = isDestructive
        ? Colors.white
        : (isDark ? AppConstants.darkBackground : Colors.white);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: EdgeInsets.symmetric(vertical: context.h(16)),
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(14)))),
        child: isLoading
            ? SizedBox(
                width: context.w(20),
                height: context.h(20),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: TextStyle(
                    fontSize: context.sp(16), fontWeight: FontWeight.bold)),
      ),
    );
  }
}
