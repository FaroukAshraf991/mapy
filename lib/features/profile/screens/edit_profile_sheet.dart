import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/update_password_screen.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';
import 'package:mapy/features/auth/widgets/password_requirements.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';
import 'package:mapy/features/profile/widgets/profile_info_tile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

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

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late final StreamSubscription<AuthState> _authSubscription;

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
    setState(() {
      _newPassword = _newPasswordController.text;
    });
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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _newPasswordController.addListener(_onNewPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);

    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _dobString = user?.userMetadata?['date_of_birth'] as String?;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  void _showError(String msg) {
    FloatingMessage.showError(context, msg);
  }

  void _showSuccess(String msg) {
    FloatingMessage.showSuccess(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(32))),
      ),
      child: Column(
        children: [
          Container(
            width: context.w(40),
            height: context.h(4),
            margin: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(context.r(2)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(20), vertical: context.h(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: textColor.withValues(alpha: 0.5),
                ),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: context.sp(20),
                  ),
                ),
                SizedBox(width: context.w(48)),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(24),
                  vertical: context.h(16),
                ),
                child: Column(
                  children: [
                    _buildAvatarSection(isDark, bgColor),
                    SizedBox(height: context.h(12)),
                    Text(
                      _nameController.text,
                      style: TextStyle(
                        fontSize: context.sp(22),
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: context.h(32)),
                    ProfileInfoTile(
                      icon: Icons.person_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Display name',
                      subtitle: _nameController.text,
                      onTap: () => _showEditNameDialog(isDark),
                      isDark: isDark,
                    ),
                    SizedBox(height: context.h(12)),
                    ProfileInfoTile(
                      icon: Icons.calendar_today_rounded,
                      iconColor: Colors.green,
                      title: 'Personal information',
                      subtitle: _dobString != null
                          ? 'Date of Birth: $_dobString'
                          : 'Set your date of birth',
                      onTap: () => _showEditDOBDialog(isDark),
                      isDark: isDark,
                    ),
                    SizedBox(height: context.h(12)),
                    ProfileInfoTile(
                      icon: Icons.email_rounded,
                      iconColor: Colors.orange,
                      title: 'Email Address',
                      subtitle: _emailController.text,
                      onTap: () => _showEditEmailDialog(isDark),
                      isDark: isDark,
                    ),
                    SizedBox(height: context.h(12)),
                    ProfileInfoTile(
                      icon: Icons.lock_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => _showEditPasswordDialog(isDark),
                      isDark: isDark,
                    ),
                    SizedBox(height: context.h(40)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark, Color bgColor) {
    return Center(
      child: Hero(
        tag: 'profileAvatar',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.blue.shade50,
              width: context.w(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: context.w(12),
                offset: Offset(0, context.h(4)),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: context.r(54),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: context.sp(38),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDOBDisplay(bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: isDark ? Colors.white24 : Colors.black38,
            size: context.sp(20),
          ),
          SizedBox(width: context.w(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date of Birth',
                style: TextStyle(
                  fontSize: context.sp(12),
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                _dobString!,
                style: TextStyle(
                  fontSize: context.sp(16),
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.lock_outline_rounded,
            color: isDark ? Colors.white10 : Colors.black12,
            size: context.sp(16),
          ),
        ],
      ),
    );
  }

  Widget _buildDOBPicker(bool isDark) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.all(context.w(16)),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: context.sp(20),
            ),
            SizedBox(width: context.w(12)),
            Text(
              _tempDOB != null
                  ? DateFormat('MMMM d, yyyy').format(_tempDOB!)
                  : 'Pick Birthday',
              style: TextStyle(
                fontSize: context.sp(16),
                color: _tempDOB != null
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white24 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
                SizedBox(height: context.h(16)),
                ProfileActionButton(
                  label: 'Save Name',
                  isLoading: _savingName,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _saveName();
                    if (mounted) navigator.pop();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: context.h(24)),
          ],
        ),
      ),
    );
  }

  void _showEditDOBDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.symmetric(
              horizontal: context.w(24), vertical: context.h(24)),
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
                title:
                    _dobString != null ? 'Personal Info' : 'Set Date of Birth',
                icon: Icons.cake_rounded,
                iconColor: Colors.purpleAccent,
                isDark: isDark,
                children: [
                  if (_dobString != null) ...[
                    _buildDOBDisplay(isDark),
                    SizedBox(height: context.h(8)),
                    Text(
                      'Date of birth cannot be changed after registration.',
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    _buildDOBPicker(isDark),
                    SizedBox(height: context.h(16)),
                    ProfileActionButton(
                      label: 'Save Date of Birth',
                      isLoading: _savingDOB,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await _saveDOB();
                        if (mounted) navigator.pop();
                      },
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              SizedBox(height: context.h(24)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEmailDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  controller: _emailController,
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
                  isLoading: _savingEmail,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _saveEmail();
                    if (mounted) navigator.pop();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: context.h(24)),
          ],
        ),
      ),
    );
  }

  void _showEditPasswordDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    controller: _currentPasswordController,
                    hint: 'Current Password',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    isPassword: true,
                  ),
                  SizedBox(height: context.h(14)),
                  ProfileTextField(
                    controller: _newPasswordController,
                    hint: 'New Password',
                    icon: Icons.lock_rounded,
                    isDark: isDark,
                    isPassword: true,
                  ),
                  SizedBox(height: context.h(8)),
                  PasswordRequirements(password: _newPassword, isDark: isDark),
                  SizedBox(height: context.h(14)),
                  ProfileTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm New Password',
                    icon: Icons.lock_rounded,
                    isDark: isDark,
                    isPassword: true,
                    showError: _showConfirmError,
                  ),
                  SizedBox(height: context.h(16)),
                  ProfileActionButton(
                    label: 'Change Password',
                    isLoading: _savingPassword,
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _changePassword();
                      if (mounted) navigator.pop();
                    },
                    isDark: isDark,
                    isDestructive: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
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
      ),
    );
  }
}
