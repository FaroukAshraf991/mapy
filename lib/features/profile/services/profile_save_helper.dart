import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/features/auth/services/auth_service.dart';
import 'package:mapy/features/auth/widgets/floating_message.dart';

class ProfileSaveHelper {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final BuildContext context;
  final void Function(VoidCallback) setState;
  final bool Function() mounted;

  bool savingName = false;
  bool savingEmail = false;
  bool savingPassword = false;
  bool savingDOB = false;
  String? dobString;
  DateTime? tempDOB;

  ProfileSaveHelper({
    required this.nameController,
    required this.emailController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.context,
    required this.setState,
    required this.mounted,
  });

  void showError(String msg) => FloatingMessage.showError(context, msg);
  void showSuccess(String msg) => FloatingMessage.showSuccess(context, msg);

  Future<void> saveName() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      showError('Name cannot be empty.');
      return;
    }
    setState(() => savingName = true);
    final error = await AuthService.updateName(name);
    if (!mounted()) return;
    setState(() => savingName = false);
    if (error != null) {
      showError(error);
    } else {
      showSuccess('Name updated successfully.');
    }
  }

  Future<void> saveEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showError('Email cannot be empty.');
      return;
    }
    setState(() => savingEmail = true);
    final error = await AuthService.updateEmail(email);
    if (!mounted()) return;
    setState(() => savingEmail = false);
    if (error != null) {
      showError(error);
    } else {
      showSuccess('Email update initiated. Please check your new email.');
    }
  }

  Future<void> changePassword() async {
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (current.isEmpty) {
      showError('Please enter your current password.');
      return;
    }
    if (current == newPass) {
      showError('New password must be different from current password.');
      return;
    }
    final passwordError = AuthService.validatePassword(newPass);
    if (passwordError != null) {
      showError(passwordError);
      return;
    }
    if (newPass != confirm) {
      showError('New passwords do not match.');
      return;
    }

    setState(() => savingPassword = true);
    final error = await AuthService.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    if (!mounted()) return;
    setState(() => savingPassword = false);
    if (error != null) {
      showError(error);
    } else {
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      showSuccess('Password changed successfully.');
    }
  }

  Future<void> handleForgotPassword() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email == null) return;
    final error = await AuthService.resetPassword(user!.email!);
    if (!mounted()) return;
    if (error == null) {
      showSuccess('Password reset link sent!');
    } else {
      showError(error);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => tempDOB = picked);
  }

  Future<void> saveDOB() async {
    if (tempDOB == null) return;
    setState(() => savingDOB = true);
    final dobStr = DateFormat('yyyy-MM-dd').format(tempDOB!);
    final error = await AuthService.updateDOB(dobStr);
    if (!mounted()) return;
    setState(() {
      savingDOB = false;
      if (error == null) dobString = dobStr;
    });
    if (error != null) {
      showError(error);
    } else {
      showSuccess('Date of Birth updated!');
    }
  }
}
