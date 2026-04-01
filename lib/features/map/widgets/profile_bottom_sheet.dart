import 'package:flutter/material.dart';
import 'package:mapy/features/profile/screens/edit_profile_sheet.dart';

class ProfileBottomSheet extends StatelessWidget {
  final String userName;
  final VoidCallback? onProfileUpdate;

  const ProfileBottomSheet({
    super.key,
    required this.userName,
    this.onProfileUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate entirely to EditProfileScreen which now owns the full
    // profile-sheet UI (avatar, name, Manage Account, Settings, Sign out).
    return EditProfileScreen(onProfileUpdate: onProfileUpdate);
  }
}
