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

/// A modern, draggable profile editing interface presented as a bottom sheet.
/// This "drawer-like" experience allows users to update their profile without
/// leaving the map context.
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
        vsync: this, duration: const Duration(milliseconds: 600));
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

  // ── LOGIC METHODS ─────────────────────────────────────────────────────────

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
      _showSuccess('Verification email sent to $email.');
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
    if (user?.email == null) return;
    final error = await AuthService.resetPassword(user!.email!);
    if (!mounted) return;
    if (error == null) {
      _showSuccess('Password reset link sent!');
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
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final url = await ProfileService.uploadAvatar(File(picked.path));

    if (!mounted) return;
    setState(() {
      _avatarUrl = url ?? _avatarUrl;
      _uploadingAvatar = false;
    });

    if (url != null) _showSuccess('Profile picture updated!');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ───────────────────────────────────────────────────
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: textColor.withValues(alpha: 0.5),
                ),
                Text('Edit Profile',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(width: 48), // Spacer to balance the close button
              ],
            ),
          ),

          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // ── Avatar Section ────────────────────────────────────────
                    _buildAvatarSection(isDark, bgColor),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 32),

                    // ── Form Sections ──────────────────────────────────────────
                    _buildNameSection(isDark),
                    const SizedBox(height: 20),
                    _buildDOBSection(isDark, textColor),
                    const SizedBox(height: 20),
                    _buildEmailSection(isDark, textColor),
                    const SizedBox(height: 20),
                    _buildPasswordSection(isDark, textColor),
                    
                    const SizedBox(height: 40),
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
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.blue.shade50,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                      )
                    : null,
              ),
            ),
            if (_uploadingAvatar)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                ),
              ),
            Positioned(
              bottom: 0, right: 0,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection(bool isDark) {
    return ProfileSectionCard(
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
    );
  }

  Widget _buildEmailSection(bool isDark, Color textColor) {
    return ProfileSectionCard(
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
        Text('A verification email will be sent to your new address.',
            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5))),
        const SizedBox(height: 16),
        ProfileActionButton(
          label: 'Update Email',
          isLoading: _savingEmail,
          onPressed: _saveEmail,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPasswordSection(bool isDark, Color textColor) {
    return ProfileSectionCard(
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword,
            child: Text('Forgot Password?',
                style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildDOBSection(bool isDark, Color textColor) {
    bool hasDOB = _dobString != null;
    return ProfileSectionCard(
      title: hasDOB ? 'Personal Info' : 'Set Date of Birth',
      icon: Icons.cake_rounded,
      iconColor: Colors.purpleAccent,
      isDark: isDark,
      children: [
        if (hasDOB) ...[
          _buildDOBDisplay(isDark),
          const SizedBox(height: 8),
          Text('Date of birth cannot be changed after registration.',
              style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.4), fontStyle: FontStyle.italic)),
        ] else ...[
          Text('Your birth date is missing. Please set it once to complete your profile.',
              style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          _buildDOBPicker(isDark),
          const SizedBox(height: 16),
          ProfileActionButton(label: 'Save Date of Birth', isLoading: _savingDOB, onPressed: _saveDOB, isDark: isDark),
        ],
      ],
    );
  }

  Widget _buildDOBDisplay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: isDark ? Colors.white24 : Colors.black38, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date of Birth',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(_dobString!,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 16),
        ],
      ),
    );
  }

  Widget _buildDOBPicker(bool isDark) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
            const SizedBox(width: 12),
            Text(
              _tempDOB != null ? DateFormat('MMMM d, yyyy').format(_tempDOB!) : 'Pick Birthday',
              style: TextStyle(
                fontSize: 16,
                color: _tempDOB != null ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white24 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
