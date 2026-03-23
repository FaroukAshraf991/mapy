import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/features/auth/services/auth_service.dart';

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

  bool _savingName = false;
  bool _savingEmail = false;
  bool _savingPassword = false;
  bool _savingDOB = false;
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
    _nameController.text =
        user?.userMetadata?['full_name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _dobString = user?.userMetadata?['date_of_birth'] as String?;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Name ─────────────────────────────────────────────────────────────────

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

  // ── Email ────────────────────────────────────────────────────────────────

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
      _showSuccess('Verification email sent to $email. Please check your inbox.');
    }
  }

  // ── Password ─────────────────────────────────────────────────────────────

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

  // ── DOB (One-time update) ───────────────────────────────────────────────

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
      setState(() {
        _dobString = dobStr; // Make it read-only now
      });
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
    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.8);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
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
                // ── Name Section ──────────────────────────────────────────
                _buildSection(
                  title: 'Display Name',
                  icon: Icons.person_rounded,
                  iconColor: Colors.blueAccent,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  textColor: textColor,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: 'Save Name',
                      isLoading: _savingName,
                      onPressed: _saveName,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Date of Birth Section ─────────────────────────────────
                if (_dobString != null)
                  _buildSection(
                    title: 'Personal Info',
                    icon: Icons.cake_rounded,
                    iconColor: Colors.purpleAccent,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    isDark: isDark,
                    textColor: textColor,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
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
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black38,
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
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black54,
                                          fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(Icons.lock_outline_rounded,
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black12,
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
                  )
                else
                  _buildSection(
                    title: 'Set Date of Birth',
                    icon: Icons.cake_rounded,
                    iconColor: Colors.purpleAccent,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    isDark: isDark,
                    textColor: textColor,
                    children: [
                      Text(
                        'Your birth date is missing. Please set it once to complete your profile.',
                        style: TextStyle(
                            fontSize: 13, color: textColor.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.shade300,
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _tempDOB != null
                                    ? DateFormat('MMMM d, yyyy')
                                        .format(_tempDOB!)
                                    : 'Pick Birthday',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: _tempDOB != null
                                        ? (isDark
                                            ? Colors.white
                                            : Colors.black87)
                                        : (isDark
                                            ? Colors.white.withOpacity(0.4)
                                            : Colors.black38)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        label: 'Save Date of Birth',
                        isLoading: _savingDOB,
                        onPressed: _saveDOB,
                        isDark: isDark,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ── Email Section ─────────────────────────────────────────
                _buildSection(
                  title: 'Email Address',
                  icon: Icons.email_rounded,
                  iconColor: Colors.orange,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  textColor: textColor,
                  children: [
                    _buildTextField(
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
                          fontSize: 12,
                          color: textColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: 'Update Email',
                      isLoading: _savingEmail,
                      onPressed: _saveEmail,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Password Section ──────────────────────────────────────
                _buildSection(
                  title: 'Change Password',
                  icon: Icons.lock_rounded,
                  iconColor: Colors.redAccent,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  textColor: textColor,
                  children: [
                    _buildTextField(
                      controller: _currentPasswordController,
                      hint: 'Current Password',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _newPasswordController,
                      hint: 'New Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm New Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: 'Change Password',
                      isLoading: _savingPassword,
                      onPressed: _changePassword,
                      isDark: isDark,
                      isDestructive: true,
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

  // ── Reusable builders ──────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
    required Color textColor,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
              ]),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor =
        isDark ? Colors.white.withOpacity(0.5) : Colors.black54;
    final iconColor =
        isDark ? Colors.white.withOpacity(0.7) : Colors.black87;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade50;

    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
                width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white : Colors.blueAccent, width: 2)),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required bool isDark,
    bool isDestructive = false,
  }) {
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
