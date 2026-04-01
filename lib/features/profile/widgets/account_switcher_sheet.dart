import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:mapy/blocs/auth/auth_cubit.dart';
import 'package:mapy/core/router/app_routes.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/services/account_storage_service.dart';
import 'package:mapy/features/profile/widgets/current_account_tile.dart';
import 'package:mapy/features/profile/widgets/switcher_account_tile.dart';
import 'package:mapy/features/profile/widgets/add_account_button.dart';
import 'package:mapy/features/profile/widgets/sign_out_button.dart';

class AccountSwitcherSheet extends StatefulWidget {
  final bool isDark;
  final String name, email;
  final Future<void> Function() onSignOut;
  final void Function(BuildContext context) onAddAccount;
  const AccountSwitcherSheet(
      {super.key,
      required this.isDark,
      required this.name,
      required this.email,
      required this.onSignOut,
      required this.onAddAccount});

  @override
  State<AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<AccountSwitcherSheet> {
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
    if (mounted)
      setState(() {
        _otherAccounts = otherAccounts;
        _isLoading = false;
      });
  }

  Future<void> _switchToAccount(StoredAccount account) async {
    setState(() => _switchingTo = account.email);
    final success = await AccountStorageService.switchTo(account);
    if (!mounted) return;
    if (success) {
      final user = Supabase.instance.client.auth.currentUser;
      final newName =
          user?.userMetadata?['full_name'] as String? ?? account.name;
      context.read<AuthCubit>().setUserName(newName);
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.push(AppRoutes.map, extra: {'userName': newName});
    } else {
      setState(() => _switchingTo = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to switch account'),
          backgroundColor: Color(0xFFE05454)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final surface =
        widget.isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5);
    final txt = widget.isDark ? Colors.white : Colors.black87;
    final sub = widget.isDark ? Colors.white54 : Colors.black45;
    final divider = widget.isDark ? Colors.white10 : Colors.black12;
    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(context.r(24)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: context.w(40),
            height: context.h(4),
            margin: EdgeInsets.symmetric(vertical: context.h(14)),
            decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(context.r(2)))),
        Center(
            child: Padding(
                padding: EdgeInsets.only(bottom: context.h(20)),
                child: Text('Choose an account',
                    style: TextStyle(
                        fontSize: context.sp(13),
                        color: sub,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)))),
        CurrentAccountTile(
            isDark: widget.isDark,
            surfaceColor: surface,
            textColor: txt,
            subtitleColor: sub,
            name: widget.name,
            email: widget.email),
        SizedBox(height: context.h(12)),
        Divider(
            color: divider,
            height: 1,
            indent: context.w(32),
            endIndent: context.w(32)),
        SizedBox(height: context.h(12)),
        _buildOtherAccounts(surface, txt, sub),
        AddAccountButton(
            surfaceColor: surface,
            textColor: txt,
            onAddAccount: () => widget.onAddAccount(context)),
        SizedBox(height: context.h(8)),
        Divider(
            color: divider,
            height: 1,
            indent: context.w(32),
            endIndent: context.w(32)),
        SizedBox(height: context.h(8)),
        SignOutButton(
            surfaceColor: surface,
            onSignOut: () {
              Navigator.pop(context);
              widget.onSignOut();
            }),
        SizedBox(height: context.h(16) + MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  Widget _buildOtherAccounts(
      Color surfaceColor, Color textColor, Color subtitleColor) {
    if (_isLoading)
      return Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(16)),
          child: const CircularProgressIndicator());
    if (_otherAccounts.isNotEmpty)
      return Column(
          children: _otherAccounts
              .map((account) => SwitcherAccountTile(
                  isDark: widget.isDark,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  account: account,
                  isSwitching: _switchingTo == account.email,
                  onSwitch: () => _switchToAccount(account)))
              .toList());
    return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(12)),
        child: Text('No other accounts',
            style: TextStyle(fontSize: context.sp(13), color: subtitleColor)));
  }
}
