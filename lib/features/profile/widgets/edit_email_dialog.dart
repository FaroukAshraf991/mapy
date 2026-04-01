import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';

class EditEmailDialog extends StatelessWidget {
  const EditEmailDialog({
    super.key,
    required this.isDark,
    required this.emailController,
    required this.savingEmail,
    required this.onSaveEmail,
  });

  final bool isDark;
  final TextEditingController emailController;
  final bool savingEmail;
  final Future<void> Function() onSaveEmail;

  static void show({
    required BuildContext context,
    required bool isDark,
    required TextEditingController emailController,
    required bool savingEmail,
    required Future<void> Function() onSaveEmail,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditEmailDialog(
        isDark: isDark,
        emailController: emailController,
        savingEmail: savingEmail,
        onSaveEmail: onSaveEmail,
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
            title: 'Email Address',
            icon: Icons.email_rounded,
            iconColor: Colors.orange,
            isDark: isDark,
            children: [
              ProfileTextField(
                controller: emailController,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: context.h(8)),
              Text(
                'A verification email will be sent to your new address.',
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: context.h(16)),
              ProfileActionButton(
                label: 'Update Email',
                isLoading: savingEmail,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await onSaveEmail();
                  nav.pop();
                },
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: context.h(24)),
        ],
      ),
    );
  }
}
