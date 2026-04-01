import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';

class EditNameDialog extends StatelessWidget {
  const EditNameDialog({
    super.key,
    required this.isDark,
    required this.nameController,
    required this.savingName,
    required this.onSaveName,
  });

  final bool isDark;
  final TextEditingController nameController;
  final bool savingName;
  final Future<void> Function() onSaveName;

  static void show({
    required BuildContext context,
    required bool isDark,
    required TextEditingController nameController,
    required bool savingName,
    required Future<void> Function() onSaveName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditNameDialog(
        isDark: isDark,
        nameController: nameController,
        savingName: savingName,
        onSaveName: onSaveName,
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
            title: 'Display Name',
            icon: Icons.person_rounded,
            iconColor: Colors.blueAccent,
            isDark: isDark,
            children: [
              ProfileTextField(
                controller: nameController,
                hint: 'Full Name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
              SizedBox(height: context.h(16)),
              ProfileActionButton(
                label: 'Save Name',
                isLoading: savingName,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await onSaveName();
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
