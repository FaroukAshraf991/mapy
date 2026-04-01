import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/switcher_avatar.dart';
import 'package:mapy/services/account_storage_service.dart';

class SwitcherAccountTile extends StatelessWidget {
  const SwitcherAccountTile({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtitleColor,
    required this.account,
    required this.isSwitching,
    required this.onSwitch,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtitleColor;
  final StoredAccount account;
  final bool isSwitching;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(10),
        ),
        leading:
            SwitcherAvatar(surfaceColor: surfaceColor, initial: accountInitial),
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
        onTap: isSwitching ? null : onSwitch,
      ),
    );
  }
}
