import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/router/app_routes.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/update_password_screen.dart';
import 'package:mapy/features/auth/screens/login_screen.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/features/auth/widgets/password_requirements.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';
import 'package:mapy/features/settings/screens/settings_screen.dart';
import 'package:mapy/services/location_share_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapy/blocs/auth/auth_cubit.dart';
import 'package:mapy/services/account_storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.onProfileUpdate});

  final VoidCallback? onProfileUpdate;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final StreamSubscription<dynamic> _authSubscription;

  bool _savingName = false;
  bool _savingEmail = false;
  bool _savingPassword = false;
  bool _savingDOB = false;
  String? _dobString;
  DateTime? _tempDOB;
  String _newPassword = '';
  String _confirmPassword = '';
  bool _confirmPasswordTouched = false;

  bool get _passwordsMatch =>
      _newPassword.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;
  bool get _showConfirmError => _confirmPasswordTouched && !_passwordsMatch;

  void _onNewPasswordChanged() {
    setState(() => _newPassword = _newPasswordController.text);
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _confirmPassword = _confirmPasswordController.text;
      _confirmPasswordTouched = true;
    });
  }

  @override
  void initState() {
    super.initState();

    _newPasswordController.addListener(_onNewPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);

    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _dobString = user?.userMetadata?['date_of_birth'] as String?;

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

  // ── Save helpers ──────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }
    setState(() => _savingName = true);
    final error = await AuthService.updateName(name);
    if (!mounted) return;
    setState(() => _savingName = false);
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Name updated successfully.');
    }
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email cannot be empty.');
      return;
    }
    setState(() => _savingEmail = true);
    final error = await AuthService.updateEmail(email);
    if (!mounted) return;
    setState(() => _savingEmail = false);
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Email update initiated. Please check your new email.');
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty) {
      _showError('Please enter your current password.');
      return;
    }
    if (current == newPass) {
      _showError('New password must be different from current password.');
      return;
    }
    final passwordError = AuthService.validatePassword(newPass);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (newPass != confirm) {
      _showError('New passwords do not match.');
      return;
    }

    setState(() => _savingPassword = true);
    final error = await AuthService.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (error != null) {
      _showError(error);
    } else {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSuccess('Password changed successfully.');
    }
  }

  Future<void> _handleForgotPassword() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email == null) return;
    final error = await AuthService.resetPassword(user!.email!);
    if (!mounted) return;
    if (error == null) {
      _showSuccess('Password reset link sent!');
    } else {
      _showError(error);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tempDOB = picked);
  }

  Future<void> _saveDOB() async {
    if (_tempDOB == null) return;
    setState(() => _savingDOB = true);
    final dobStr = DateFormat('yyyy-MM-dd').format(_tempDOB!);
    final error = await AuthService.updateDOB(dobStr);
    if (!mounted) return;
    setState(() {
      _savingDOB = false;
      if (error == null) _dobString = dobStr;
    });
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Date of Birth updated!');
    }
  }

  void _showError(String msg) => FloatingMessage.showError(context, msg);
  void _showSuccess(String msg) => FloatingMessage.showSuccess(context, msg);

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Manage Account sheet ──────────────────────────────────────────────────

  void _showManageAccount(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManageAccountSheet(
        isDark: isDark,
        nameController: _nameController,
        emailController: _emailController,
        currentPasswordController: _currentPasswordController,
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        savingName: _savingName,
        savingEmail: _savingEmail,
        savingPassword: _savingPassword,
        savingDOB: _savingDOB,
        dobString: _dobString,
        tempDOB: _tempDOB,
        newPassword: _newPassword,
        showConfirmError: _showConfirmError,
        onSaveName: _saveName,
        onSaveEmail: _saveEmail,
        onChangePassword: _changePassword,
        onForgotPassword: _handleForgotPassword,
        onPickDate: _pickDate,
        onSaveDOB: _saveDOB,
      ),
    ).then((_) {
      setState(() {});
      widget.onProfileUpdate?.call();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.modalBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      // compact height — just enough for the three sections
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.r(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: context.w(24),
            spreadRadius: context.w(4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle ──────────────────────────────────────────────
          Container(
            width: context.w(40),
            height: context.h(4),
            margin: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(context.r(2)),
            ),
          ),

          // ── avatar + name + manage button ────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(8),
              context.w(20),
              context.h(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // avatar
                Hero(
                  tag: 'profileAvatar',
                  child: CircleAvatar(
                    radius: context.r(36),
                    backgroundColor: const Color(0xFF5B8DEF),
                    child: Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: context.sp(28),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.h(16)),

                // name
                Text(
                  _nameController.text,
                  style: TextStyle(
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: context.h(10)),

                // manage your account button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showManageAccount(isDark),
                    borderRadius: BorderRadius.circular(context.r(24)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(20),
                        vertical: context.h(10),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        borderRadius: BorderRadius.circular(context.r(24)),
                      ),
                      child: Text(
                        'Manage your Account',
                        style: TextStyle(
                          fontSize: context.sp(14),
                          color: const Color(0xFF5B8DEF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 1,
          ),

          // ── settings row ─────────────────────────────────────────────
          _MenuItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 1,
          ),

          // ── share my location row ─────────────────────────────────────
          _MenuItem(
            icon: Icons.share_location_rounded,
            label: 'Share My Location',
            isDark: isDark,
            onTap: () async {
              Navigator.pop(context);
              try {
                final permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  await Geolocator.requestPermission();
                }
                final position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                );
                await LocationShareService.shareLocation(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  placeName: 'My Current Location',
                );
              } catch (e) {
                _showError('Unable to share location: $e');
              }
            },
          ),

          SizedBox(height: context.h(4)),
          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 1,
          ),

          // ── sign out row ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(4)),
            child: _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: const Color(0xFFE05454),
              isDark: isDark,
              onTap: _signOut,
            ),
          ),

          SizedBox(height: context.h(8)),
        ],
      ),
    );
  }
}

// ── Reusable menu item ────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isDark ? Colors.white70 : Colors.black54);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(24)),
      leading: Icon(icon, color: effectiveColor, size: context.sp(24)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(15),
          fontWeight: FontWeight.w600,
          color: color ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Manage Account bottom sheet ───────────────────────────────────────────────

class _ManageAccountSheet extends StatelessWidget {
  const _ManageAccountSheet({
    required this.isDark,
    required this.nameController,
    required this.emailController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.savingName,
    required this.savingEmail,
    required this.savingPassword,
    required this.savingDOB,
    required this.dobString,
    required this.tempDOB,
    required this.newPassword,
    required this.showConfirmError,
    required this.onSaveName,
    required this.onSaveEmail,
    required this.onChangePassword,
    required this.onForgotPassword,
    required this.onPickDate,
    required this.onSaveDOB,
  });

  final bool isDark;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool savingName;
  final bool savingEmail;
  final bool savingPassword;
  final bool savingDOB;
  final String? dobString;
  final DateTime? tempDOB;
  final String newPassword;
  final bool showConfirmError;
  final Future<void> Function() onSaveName;
  final Future<void> Function() onSaveEmail;
  final Future<void> Function() onChangePassword;
  final Future<void> Function() onForgotPassword;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onSaveDOB;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final tileBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(28))),
      ),
      child: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(4),
                context.h(12),
                context.w(4),
                context.h(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: textColor, size: context.sp(22)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Mapy Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: context.sp(18),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline_rounded,
                        color: textColor, size: context.sp(22)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded,
                        color: textColor, size: context.sp(22)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.h(8)),

                  // ── Profile row ─────────────────────────────────────────
                  // ── Profile row (tappable → account switcher) ────────────────
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _showAccountSwitcher(context, bgColor, subtitleColor),
                      borderRadius: BorderRadius.circular(context.r(16)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(20),
                          vertical: context.h(8),
                        ),
                        child: Row(
                          children: [
                            // Avatar with colorful ring + camera badge
                            Stack(
                              children: [
                                // Colorful ring
                                Container(
                                  width: context.r(72),
                                  height: context.r(72),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const SweepGradient(
                                      colors: [
                                        Color(0xFF4285F4), // blue
                                        Color(0xFF34A853), // green
                                        Color(0xFFFBBC05), // yellow
                                        Color(0xFFEA4335), // red
                                        Color(0xFF4285F4), // back to blue
                                      ],
                                    ),
                                  ),
                                ),
                                // White gap ring
                                Positioned(
                                  top: context.r(3),
                                  left: context.r(3),
                                  child: Container(
                                    width: context.r(66),
                                    height: context.r(66),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: bgColor,
                                    ),
                                  ),
                                ),
                                // Avatar itself
                                Positioned(
                                  top: context.r(5),
                                  left: context.r(5),
                                  child: CircleAvatar(
                                    radius: context.r(31),
                                    backgroundColor: const Color(0xFF5B8DEF),
                                    child: Text(
                                      nameController.text.isNotEmpty
                                          ? nameController.text[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: context.sp(24),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                // Camera badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: context.r(22),
                                    height: context.r(22),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: bgColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: subtitleColor,
                                      size: context.sp(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(width: context.w(16)),

                            // Name + email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameController.text.isNotEmpty
                                        ? nameController.text
                                        : 'Your Name',
                                    style: TextStyle(
                                      fontSize: context.sp(20),
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppConstants.darkBackground,
                                    ),
                                  ),
                                  SizedBox(height: context.h(3)),
                                  Text(
                                    emailController.text,
                                    style: TextStyle(
                                      fontSize: context.sp(13),
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Chevron (animated hint)
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: subtitleColor,
                              size: context.sp(26),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: context.h(28)),

                  // ── Tiles ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                    child: Column(
                      children: [
                        _AccountTile(
                          iconBg: const Color(0xFF3D7A47),
                          icon: Icons.person_rounded,
                          title: 'Account Name',
                          subtitle: 'Display name',
                          isDark: isDark,
                          tileBg: tileBg,
                          onTap: () => _showEditNameDialog(context),
                        ),
                        SizedBox(height: context.h(10)),
                        _AccountTile(
                          iconBg: const Color(0xFF2F5FC4),
                          icon: Icons.shield_rounded,
                          title: 'Password and security',
                          subtitle: 'Change password',
                          isDark: isDark,
                          tileBg: tileBg,
                          onTap: () => _showEditPasswordDialog(context),
                        ),
                        SizedBox(height: context.h(10)),
                        _AccountTile(
                          iconBg: const Color(0xFFB85C1A),
                          icon: Icons.email_rounded,
                          title: 'Email Address',
                          subtitle: emailController.text,
                          isDark: isDark,
                          tileBg: tileBg,
                          onTap: () => _showEditEmailDialog(context),
                        ),
                        SizedBox(height: context.h(10)),
                        _AccountTile(
                          iconBg: const Color(0xFF7B4FBF),
                          icon: Icons.cake_rounded,
                          title: 'Date of Birth',
                          subtitle: dobString ?? 'Not set',
                          isDark: isDark,
                          tileBg: tileBg,
                          onTap: () => _showEditDOBDialog(context),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.h(40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Switcher ───────────────────────────────────────────────────

  void _showAccountSwitcher(
    BuildContext context,
    Color bgColor,
    Color subtitleColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSwitcherSheet(
        isDark: isDark,
        name: nameController.text,
        email: emailController.text,
        onSignOut: () async {
          // Use AuthCubit.logout() — GoRouter redirect handles navigation automatically
          await context.read<AuthCubit>().logout();
        },
        onAddAccount: (BuildContext sheetContext) {
          // Dismiss all sheets, then PUSH /add-account on top of /map.
          // push() keeps the map route (and MapCubit) alive — go() would destroy it.
          Navigator.of(sheetContext).popUntil((route) => route.isFirst);
          sheetContext.push(AppRoutes.addAccount);
        },
      ),
    );
  }

  // ── sub-dialogs ─────────────────────────────────────────────────────

  void _showEditNameDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: ctx.w(24),
          right: ctx.w(24),
          top: ctx.h(24),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.modalBackground : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ctx.r(24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(ctx),
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
                SizedBox(height: ctx.h(16)),
                ProfileActionButton(
                  label: 'Save Name',
                  isLoading: savingName,
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    await onSaveName();
                    nav.pop();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: ctx.h(24)),
          ],
        ),
      ),
    );
  }

  void _showEditDOBDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: ctx.w(24),
            vertical: ctx.h(24),
          ),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.modalBackground : Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(ctx.r(24))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(ctx),
              ProfileSectionCard(
                title:
                    dobString != null ? 'Personal Info' : 'Set Date of Birth',
                icon: Icons.cake_rounded,
                iconColor: Colors.purpleAccent,
                isDark: isDark,
                children: [
                  if (dobString != null) ...[
                    _buildDOBDisplay(ctx),
                    SizedBox(height: ctx.h(8)),
                    Text(
                      'Date of birth cannot be changed after registration.',
                      style: TextStyle(
                        fontSize: ctx.sp(11),
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    _buildDOBPicker(ctx),
                    SizedBox(height: ctx.h(16)),
                    ProfileActionButton(
                      label: 'Save Date of Birth',
                      isLoading: savingDOB,
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        await onSaveDOB();
                        nav.pop();
                      },
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              SizedBox(height: ctx.h(24)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: ctx.w(24),
          right: ctx.w(24),
          top: ctx.h(24),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.modalBackground : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ctx.r(24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(ctx),
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
                SizedBox(height: ctx.h(8)),
                Text(
                  'A verification email will be sent to your new address.',
                  style: TextStyle(
                    fontSize: ctx.sp(12),
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: ctx.h(16)),
                ProfileActionButton(
                  label: 'Update Email',
                  isLoading: savingEmail,
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    await onSaveEmail();
                    nav.pop();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: ctx.h(24)),
          ],
        ),
      ),
    );
  }

  void _showEditPasswordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: ctx.w(24),
          right: ctx.w(24),
          top: ctx.h(24),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.modalBackground : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ctx.r(24))),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(ctx),
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
                  SizedBox(height: ctx.h(14)),
                  ProfileTextField(
                    controller: newPasswordController,
                    hint: 'New Password',
                    icon: Icons.lock_rounded,
                    isDark: isDark,
                    isPassword: true,
                  ),
                  SizedBox(height: ctx.h(8)),
                  PasswordRequirements(
                    password: newPassword,
                    isDark: isDark,
                  ),
                  SizedBox(height: ctx.h(14)),
                  ProfileTextField(
                    controller: confirmPasswordController,
                    hint: 'Confirm New Password',
                    icon: Icons.lock_rounded,
                    isDark: isDark,
                    isPassword: true,
                    showError: showConfirmError,
                  ),
                  SizedBox(height: ctx.h(16)),
                  ProfileActionButton(
                    label: 'Change Password',
                    isLoading: savingPassword,
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
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
                          fontSize: ctx.sp(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ctx.h(24)),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Widget _sheetHandle(BuildContext ctx) => Container(
        width: ctx.w(40),
        height: ctx.h(4),
        margin: EdgeInsets.only(bottom: ctx.h(20)),
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black12,
          borderRadius: BorderRadius.circular(ctx.r(2)),
        ),
      );

  Widget _buildDOBDisplay(BuildContext ctx) => Container(
        padding: EdgeInsets.all(ctx.w(16)),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(ctx.r(14)),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: isDark ? Colors.white24 : Colors.black38,
                size: ctx.sp(20)),
            SizedBox(width: ctx.w(12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date of Birth',
                    style: TextStyle(
                        fontSize: ctx.sp(12),
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: ctx.h(2)),
                Text(dobString!,
                    style: TextStyle(
                        fontSize: ctx.sp(16),
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Icon(Icons.lock_outline_rounded,
                color: isDark ? Colors.white10 : Colors.black12,
                size: ctx.sp(16)),
          ],
        ),
      );

  Widget _buildDOBPicker(BuildContext ctx) => GestureDetector(
        onTap: onPickDate,
        child: Container(
          padding: EdgeInsets.all(ctx.w(16)),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(ctx.r(14)),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: ctx.sp(20)),
              SizedBox(width: ctx.w(12)),
              Text(
                tempDOB != null
                    ? DateFormat('MMMM d, yyyy').format(tempDOB!)
                    : 'Pick Birthday',
                style: TextStyle(
                  fontSize: ctx.sp(16),
                  color: tempDOB != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white24 : Colors.black38),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Account tile widget ────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.tileBg,
    required this.onTap,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color tileBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Material(
      color: tileBg,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(16),
          ),
          child: Row(
            children: [
              // Colored circle icon
              Container(
                width: context.r(42),
                height: context.r(42),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: context.sp(20),
                ),
              ),
              SizedBox(width: context.w(16)),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.sp(13),
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
                size: context.sp(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Account Switcher Sheet ────────────────────────────────────────────────────

class _AccountSwitcherSheet extends StatefulWidget {
  const _AccountSwitcherSheet({
    required this.isDark,
    required this.name,
    required this.email,
    required this.onSignOut,
    required this.onAddAccount,
  });

  final bool isDark;
  final String name;
  final String email;
  final Future<void> Function() onSignOut;
  final void Function(BuildContext context) onAddAccount;

  @override
  State<_AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<_AccountSwitcherSheet> {
  List<StoredAccount> _otherAccounts = [];
  bool _isLoading = true;
  String? _switchingTo;

  @override
  void initState() {
    super.initState();
    _loadOtherAccounts();
  }

  Future<void> _loadOtherAccounts() async {
    final allAccounts = await AccountStorageService.getAccounts();
    final currentEmail = widget.email.toLowerCase();
    final otherAccounts = allAccounts
        .where((a) => a.email.toLowerCase() != currentEmail)
        .toList();
    if (mounted) {
      setState(() {
        _otherAccounts = otherAccounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchToAccount(StoredAccount account) async {
    setState(() => _switchingTo = account.email);
    final success = await AccountStorageService.switchTo(account);
    if (mounted) {
      if (success) {
        final user = Supabase.instance.client.auth.currentUser;
        final newName =
            user?.userMetadata?['full_name'] as String? ?? account.name;
        context.read<AuthCubit>().setUserName(newName);
        Navigator.of(context).popUntil((route) => route.isFirst);
        context.push(AppRoutes.map, extra: {'userName': newName});
      } else {
        setState(() => _switchingTo = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch account'),
            backgroundColor: Color(0xFFE05454),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final surfaceColor =
        widget.isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDark ? Colors.white54 : Colors.black45;
    final dividerColor = widget.isDark ? Colors.white10 : Colors.black12;

    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(24))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: context.w(40),
            height: context.h(4),
            margin: EdgeInsets.symmetric(vertical: context.h(14)),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(context.r(2)),
            ),
          ),

          // Title
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.h(20)),
              child: Text(
                'Choose an account',
                style: TextStyle(
                  fontSize: context.sp(13),
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Current account tile
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(16)),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(
                color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(10),
              ),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Colorful ring
                  Container(
                    width: context.r(48),
                    height: context.r(48),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFF4285F4),
                          Color(0xFF34A853),
                          Color(0xFFFBBC05),
                          Color(0xFFEA4335),
                          Color(0xFF4285F4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: context.r(2),
                    left: context.r(2),
                    child: Container(
                      width: context.r(44),
                      height: context.r(44),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                      ),
                    ),
                  ),
                  Positioned(
                    top: context.r(4),
                    left: context.r(4),
                    child: CircleAvatar(
                      radius: context.r(20),
                      backgroundColor: const Color(0xFF5B8DEF),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.name.isNotEmpty ? widget.name : 'Your Name',
                style: TextStyle(
                  fontSize: context.sp(15),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                widget.email,
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: subtitleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                width: context.r(28),
                height: context.r(28),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4285F4),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: context.sp(16),
                ),
              ),
            ),
          ),

          SizedBox(height: context.h(12)),
          Divider(
              color: dividerColor,
              height: 1,
              indent: context.w(32),
              endIndent: context.w(32)),
          SizedBox(height: context.h(12)),

          // Other accounts
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(16)),
              child: const CircularProgressIndicator(),
            )
          else if (_otherAccounts.isNotEmpty)
            ..._otherAccounts.map((account) => _buildAccountTile(
                  account: account,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  dividerColor: dividerColor,
                ))
          else if (_otherAccounts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              child: Text(
                'No other accounts',
                style: TextStyle(
                  fontSize: context.sp(13),
                  color: subtitleColor,
                ),
              ),
            ),

          // Add another account
          ListTile(
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
            onTap: () {
              widget.onAddAccount(context);
            },
          ),

          Divider(
              color: dividerColor,
              height: 1,
              indent: context.w(20),
              endIndent: context.w(20)),

          // Sign out
          ListTile(
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
            onTap: () {
              Navigator.pop(context);
              widget.onSignOut();
            },
          ),

          SizedBox(
              height: context.h(16) + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required StoredAccount account,
    required Color surfaceColor,
    required Color textColor,
    required Color subtitleColor,
    required Color dividerColor,
  }) {
    final isSwitching = _switchingTo == account.email;
    final accountInitial =
        account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U';

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.w(16),
        0,
        context.w(16),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(10),
        ),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: context.r(48),
              height: context.r(48),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF34A853),
                    Color(0xFFFBBC05),
                    Color(0xFFEA4335),
                    Color(0xFF4285F4),
                  ],
                ),
              ),
            ),
            Positioned(
              top: context.r(2),
              left: context.r(2),
              child: Container(
                width: context.r(44),
                height: context.r(44),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                ),
              ),
            ),
            Positioned(
              top: context.r(4),
              left: context.r(4),
              child: CircleAvatar(
                radius: context.r(20),
                backgroundColor: const Color(0xFF5B8DEF),
                child: isSwitching
                    ? SizedBox(
                        width: context.r(18),
                        height: context.r(18),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        accountInitial,
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        title: Text(
          account.name.isNotEmpty ? account.name : 'Unknown',
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          account.email,
          style: TextStyle(
            fontSize: context.sp(12),
            color: subtitleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: isSwitching ? null : () => _switchToAccount(account),
      ),
    );
  }
}
