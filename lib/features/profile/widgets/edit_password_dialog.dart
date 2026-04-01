import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/widgets/password_requirements.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';

class EditPasswordDialog extends StatelessWidget {
  const EditPasswordDialog({
    super.key,
    required this.isDark,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.newPassword,
    required this.showConfirmError,
    required this.savingPassword,
    required this.onChangePassword,
    required this.onForgotPassword,
  });

  final bool isDark;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String newPassword;
  final bool showConfirmError;
  final bool savingPassword;
  final Future<void> Function() onChangePassword;
  final Future<void> Function() onForgotPassword;

  static void show({
    required BuildContext context,
    required bool isDark,
    required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmPasswordController,
    required String newPassword,
    required bool showConfirmError,
    required bool savingPassword,
    required Future<void> Function() onChangePassword,
    required Future<void> Function() onForgotPassword,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPasswordDialog(
        isDark: isDark,
        currentPasswordController: currentPasswordController,
        newPasswordController: newPasswordController,
        confirmPasswordController: confirmPasswordController,
        newPassword: newPassword,
        showConfirmError: showConfirmError,
        savingPassword: savingPassword,
        onChangePassword: onChangePassword,
        onForgotPassword: onForgotPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: context.w(24),
        right: context.w(24),
        top: context.h(24),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.modalBackground : Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(24))),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(40),
              height: context.h(4),
              margin: EdgeInsets.only(bottom: context.h(20)),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(context.r(2)),
              ),
            ),
            ProfileSectionCard(
              title: 'Change Password',
              icon: Icons.lock_rounded,
              iconColor: Colors.redAccent,
              isDark: isDark,
              children: [
                ProfileTextField(
                  controller: currentPasswordController,
                  hint: 'Current Password',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  isPassword: true,
                ),
                SizedBox(height: context.h(14)),
                ProfileTextField(
                  controller: newPasswordController,
                  hint: 'New Password',
                  icon: Icons.lock_rounded,
                  isDark: isDark,
                  isPassword: true,
                ),
                SizedBox(height: context.h(8)),
                PasswordRequirements(
                  password: newPassword,
                  isDark: isDark,
                ),
                SizedBox(height: context.h(14)),
                ProfileTextField(
                  controller: confirmPasswordController,
                  hint: 'Confirm New Password',
                  icon: Icons.lock_rounded,
                  isDark: isDark,
                  isPassword: true,
                  showError: showConfirmError,
                ),
                SizedBox(height: context.h(16)),
                ProfileActionButton(
                  label: 'Change Password',
                  isLoading: savingPassword,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await onChangePassword();
                    nav.pop();
                  },
                  isDark: isDark,
                  isDestructive: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: context.sp(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(24)),
          ],
        ),
      ),
    );
  }
}
