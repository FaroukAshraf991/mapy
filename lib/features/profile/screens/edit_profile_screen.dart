import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/services/profile_service.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/screens/update_password_screen.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';

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
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  String? _dobString;
  DateTime? _tempDOB;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _dobString = user?.userMetadata?['date_of_birth'] as String?;

    _loadAvatar();

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
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Logic Methods ────────────────────────────────────────────────────────

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
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }
    setState(() => _savingEmail = true);
    final error = await AuthService.updateEmail(email);
    if (!mounted) return;
    setState(() => _savingEmail = false);
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess(
          'Verification email sent to $email. Please check your inbox.');
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
    if (newPass.length < 6) {
      _showError('New password must be at least 6 characters.');
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
    if (user?.email == null) {
      _showError('No user email found.');
      return;
    }
    final error = await AuthService.resetPassword(user!.email!);
    if (!mounted) return;
    if (error == null) {
      _showSuccess('Password reset link sent to ${user.email}!');
    } else {
      _showError(error);
    }
  }

  Future<void> _loadAvatar() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _avatarUrl = profile.avatarUrl);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);

    final url = await ProfileService.uploadAvatar(File(picked.path));

    if (!mounted) return;
    setState(() {
      _avatarUrl = url ?? _avatarUrl;
      _uploadingAvatar = false;
    });

    if (url != null) {
      _showSuccess('Profile picture updated!');
    } else {
      _showError('Upload failed. Please try again.');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() => _tempDOB = picked);
    }
  }

  Future<void> _saveDOB() async {
    if (_tempDOB == null) {
      _showError('Please select a date first.');
      return;
    }
    setState(() => _savingDOB = true);
    final dobStr = DateFormat('yyyy-MM-dd').format(_tempDOB!);
    final error = await AuthService.updateDOB(dobStr);
    if (!mounted) return;
    setState(() => _savingDOB = false);
    if (error != null) {
      _showError(error);
    } else {
      setState(() => _dobString = dobStr);
      _showSuccess('Date of Birth updated successfully.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Avatar Section ────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.blue.shade100,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppConstants.darkBackground,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (_uploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: bgColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _nameController.text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Name Section ──────────────────────────────────────────
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
                    const SizedBox(height: 16),
                    ProfileActionButton(
                      label: 'Save Name',
                      isLoading: _savingName,
                      onPressed: _saveName,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Date of Birth Section ─────────────────────────────────
                _buildDOBSection(isDark, textColor),

                const SizedBox(height: 20),

                // ── Email Section ─────────────────────────────────────────
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
                    const SizedBox(height: 8),
                    Text(
                      'A verification email will be sent to your new address.',
                      style: TextStyle(
                          fontSize: 12, color: textColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    ProfileActionButton(
                      label: 'Update Email',
                      isLoading: _savingEmail,
                      onPressed: _saveEmail,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Password Section ──────────────────────────────────────
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
                    const SizedBox(height: 14),
                    ProfileTextField(
                      controller: _newPasswordController,
                      hint: 'New Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    ProfileTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm New Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    ProfileActionButton(
                      label: 'Change Password',
                      isLoading: _savingPassword,
                      onPressed: _changePassword,
                      isDark: isDark,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : AppConstants.darkBackground.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section-specific builders for complex logic ──────────────────────────

  Widget _buildDOBSection(bool isDark, Color textColor) {
    if (_dobString != null) {
      return ProfileSectionCard(
        title: 'Personal Info',
        icon: Icons.cake_rounded,
        iconColor: Colors.purpleAccent,
        isDark: isDark,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
                    size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black45,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dobString!,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.lock_outline_rounded,
                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.black12,
                    size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date of birth cannot be changed after registration.',
            style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.4),
                fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    return ProfileSectionCard(
      title: 'Set Date of Birth',
      icon: Icons.cake_rounded,
      iconColor: Colors.purpleAccent,
      isDark: isDark,
      children: [
        Text(
          'Your birth date is missing. Please set it once to complete your profile.',
          style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                  width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: isDark ? Colors.white70 : Colors.black87, size: 20),
                const SizedBox(width: 12),
                Text(
                  _tempDOB != null
                      ? DateFormat('MMMM d, yyyy').format(_tempDOB!)
                      : 'Pick Birthday',
                  style: TextStyle(
                      fontSize: 16,
                      color: _tempDOB != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white.withOpacity(0.4) : Colors.black38)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ProfileActionButton(
          label: 'Save Date of Birth',
          isLoading: _savingDOB,
          onPressed: _saveDOB,
          isDark: isDark,
        ),
      ],
    );
  }
}
