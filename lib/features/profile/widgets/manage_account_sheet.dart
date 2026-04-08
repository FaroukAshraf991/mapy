import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapy/blocs/auth/auth_cubit.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/router/app_routes.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/account_switcher_sheet.dart';
import 'package:mapy/features/profile/widgets/account_tile.dart';
import 'package:mapy/features/profile/widgets/edit_name_dialog.dart';
import 'package:mapy/features/profile/widgets/edit_dob_dialog.dart';
import 'package:mapy/features/profile/widgets/edit_email_dialog.dart';
import 'package:mapy/features/profile/widgets/edit_password_dialog.dart';
class ManageAccountSheet extends StatelessWidget {
  final bool isDark;
  final TextEditingController nameController,
      emailController,
      currentPasswordController,
      newPasswordController,
      confirmPasswordController;
  final bool savingName,
      savingEmail,
      savingPassword,
      savingDOB,
      showConfirmError;
  final String? dobString;
  final DateTime? tempDOB;
  final String newPassword;
  final Future<void> Function() onSaveName,
      onSaveEmail,
      onChangePassword,
      onForgotPassword,
      onPickDate,
      onSaveDOB;
  const ManageAccountSheet(
      {super.key,
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
      required this.onSaveDOB});
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final txt = isDark ? Colors.white : AppConstants.darkBackground;
    final sub = isDark ? Colors.white54 : Colors.black45;
    final tileBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2);
    final effectiveHeight =
        (context.screenHeight * 0.92).clamp(0.0, context.maxSheetHeight);
    return Container(
        height: effectiveHeight,
        decoration: BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.r(28)))),
        child: Column(children: [
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.w(4), context.h(12), context.w(4), context.h(4)),
                  child: Row(children: [
                    IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: txt, size: context.sp(22)),
                        tooltip: 'Close account manager',
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                        child: Text('Mapy Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: txt,
                                fontWeight: FontWeight.w700,
                                fontSize: context.sp(18)))),
                    IconButton(
                        icon: Icon(Icons.help_outline_rounded,
                            color: txt, size: context.sp(22)),
                        tooltip: 'Help and support',
                        onPressed: () {}),
                    IconButton(
                        icon: Icon(Icons.search_rounded,
                            color: txt, size: context.sp(22)),
                        tooltip: 'Search account settings',
                        onPressed: () {})
                  ]))),
          Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.h(8)),
                        _profileRow(context, bg, sub),
                        SizedBox(height: context.h(28)),
                        _tiles(context, tileBg),
                        SizedBox(height: context.h(40))
                      ]))),
        ]));
  }
  Widget _profileRow(BuildContext c, Color bg, Color sub) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: () => _showAccountSwitcher(c),
          borderRadius: BorderRadius.circular(c.r(16)),
          child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: c.w(20), vertical: c.h(8)),
              child: Row(children: [
                _avatar(c, bg, sub),
                SizedBox(width: c.w(16)),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          nameController.text.isNotEmpty
                              ? nameController.text
                              : 'Your Name',
                          style: TextStyle(
                              fontSize: c.sp(20),
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppConstants.darkBackground)),
                      SizedBox(height: c.h(3)),
                      Text(emailController.text,
                          style: TextStyle(fontSize: c.sp(13), color: sub))
                    ])),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: sub, size: c.sp(26))
              ]))));
  Widget _avatar(BuildContext c, Color bg, Color sub) => Stack(children: [
        Container(
            width: c.r(72),
            height: c.r(72),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  Color(0xFF4285F4),
                  Color(0xFF34A853),
                  Color(0xFFFBBC05),
                  Color(0xFFEA4335),
                  Color(0xFF4285F4)
                ]))),
        Positioned(
            top: c.r(3),
            left: c.r(3),
            child: Container(
                width: c.r(66),
                height: c.r(66),
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg))),
        Positioned(
            top: c.r(5),
            left: c.r(5),
            child: CircleAvatar(
                radius: c.r(31),
                backgroundColor: const Color(0xFF5B8DEF),
                child: Text(
                    nameController.text.isNotEmpty
                        ? nameController.text[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                        fontSize: c.sp(24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white)))),
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
                width: c.r(22),
                height: c.r(22),
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: bg, width: 1.5)),
                child:
                    Icon(Icons.camera_alt_rounded, color: sub, size: c.sp(12))))
      ]);
  Widget _tiles(BuildContext c, Color tileBg) => Padding(
      padding: EdgeInsets.symmetric(horizontal: c.w(16)),
      child: Column(children: [
        AccountTile(
            iconBg: const Color(0xFF3D7A47),
            icon: Icons.person_rounded,
            title: 'Account Name',
            subtitle: 'Display name',
            isDark: isDark,
            tileBg: tileBg,
            onTap: () => EditNameDialog.show(
                context: c,
                isDark: isDark,
                nameController: nameController,
                savingName: savingName,
                onSaveName: onSaveName)),
        SizedBox(height: c.h(10)),
        AccountTile(
            iconBg: const Color(0xFF2F5FC4),
            icon: Icons.shield_rounded,
            title: 'Password and security',
            subtitle: 'Change password',
            isDark: isDark,
            tileBg: tileBg,
            onTap: () => EditPasswordDialog.show(
                context: c,
                isDark: isDark,
                currentPasswordController: currentPasswordController,
                newPasswordController: newPasswordController,
                confirmPasswordController: confirmPasswordController,
                newPassword: newPassword,
                showConfirmError: showConfirmError,
                savingPassword: savingPassword,
                onChangePassword: onChangePassword,
                onForgotPassword: onForgotPassword)),
        SizedBox(height: c.h(10)),
        AccountTile(
            iconBg: const Color(0xFFB85C1A),
            icon: Icons.email_rounded,
            title: 'Email Address',
            subtitle: emailController.text,
            isDark: isDark,
            tileBg: tileBg,
            onTap: () => EditEmailDialog.show(
                context: c,
                isDark: isDark,
                emailController: emailController,
                savingEmail: savingEmail,
                onSaveEmail: onSaveEmail)),
        SizedBox(height: c.h(10)),
        AccountTile(
            iconBg: const Color(0xFF7B4FBF),
            icon: Icons.cake_rounded,
            title: 'Date of Birth',
            subtitle: dobString ?? 'Not set',
            isDark: isDark,
            tileBg: tileBg,
            onTap: () => EditDOBDialog.show(
                context: c,
                isDark: isDark,
                dobString: dobString,
                tempDOB: tempDOB,
                savingDOB: savingDOB,
                onPickDate: onPickDate,
                onSaveDOB: onSaveDOB)),
      ]));
  void _showAccountSwitcher(BuildContext c) => showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountSwitcherSheet(
          isDark: isDark,
          name: nameController.text,
          email: emailController.text,
          onSignOut: () async => await c.read<AuthCubit>().logout(),
          onAddAccount: (sc) {
            Navigator.of(sc).popUntil((r) => r.isFirst);
            sc.push(AppRoutes.addAccount);
          }));
}
