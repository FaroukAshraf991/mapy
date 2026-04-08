import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/auth/screens/update_password_screen.dart';
import 'package:mapy/features/profile/widgets/manage_account_sheet.dart';
import 'package:mapy/features/profile/widgets/edit_profile_builder.dart';
import 'package:mapy/features/profile/services/profile_save_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.onProfileUpdate});

  final VoidCallback? onProfileUpdate;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final StreamSubscription<dynamic> _authSubscription;
  late final ProfileSaveHelper _saveHelper;

  String _newPassword = '';
  String _confirmPassword = '';
  bool _confirmPasswordTouched = false;

  bool get _passwordsMatch =>
      _newPassword.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;
  bool get _showConfirmError => _confirmPasswordTouched && !_passwordsMatch;

  @override
  void initState() {
    super.initState();

    _newPasswordController.addListener(() {
      setState(() => _newPassword = _newPasswordController.text);
    });
    _confirmPasswordController.addListener(() {
      setState(() {
        _confirmPassword = _confirmPasswordController.text;
        _confirmPasswordTouched = true;
      });
    });

    _saveHelper = ProfileSaveHelper(
      nameController: _nameController,
      emailController: _emailController,
      currentPasswordController: _currentPasswordController,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
      context: context,
      setState: setState,
      mounted: () => mounted,
    );

    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _saveHelper.dobString = user?.userMetadata?['date_of_birth'] as String?;

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showManageAccount(bool isDark) {
    final maxSheetWidth = context.adaptiveValue(
      mobile: double.infinity,
      tablet: AppConstants.maxSheetWidthTablet,
      desktop: AppConstants.maxSheetWidthDesktop,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: maxSheetWidth == double.infinity
          ? null
          : BoxConstraints(maxWidth: maxSheetWidth),
      builder: (_) => ManageAccountSheet(
        isDark: isDark,
        nameController: _nameController,
        emailController: _emailController,
        currentPasswordController: _currentPasswordController,
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        savingName: _saveHelper.savingName,
        savingEmail: _saveHelper.savingEmail,
        savingPassword: _saveHelper.savingPassword,
        savingDOB: _saveHelper.savingDOB,
        dobString: _saveHelper.dobString,
        tempDOB: _saveHelper.tempDOB,
        newPassword: _newPassword,
        showConfirmError: _showConfirmError,
        onSaveName: _saveHelper.saveName,
        onSaveEmail: _saveHelper.saveEmail,
        onChangePassword: _saveHelper.changePassword,
        onForgotPassword: _saveHelper.handleForgotPassword,
        onPickDate: _saveHelper.pickDate,
        onSaveDOB: _saveHelper.saveDOB,
      ),
    ).then((_) {
      setState(() {});
      widget.onProfileUpdate?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return EditProfileBuilder.buildProfileCard(
      context: context,
      isDark: isDark,
      name: _nameController.text,
      onManageAccount: () => _showManageAccount(isDark),
      onSettings: () {},
      onShareLocation: () {},
      onSignOut: () async {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      showError: _saveHelper.showError,
    );
  }
}
