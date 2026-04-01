import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/profile/widgets/profile_widgets.dart';

class EditDOBDialog extends StatelessWidget {
  const EditDOBDialog({
    super.key,
    required this.isDark,
    required this.dobString,
    required this.tempDOB,
    required this.savingDOB,
    required this.onPickDate,
    required this.onSaveDOB,
  });

  final bool isDark;
  final String? dobString;
  final DateTime? tempDOB;
  final bool savingDOB;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onSaveDOB;

  static void show({
    required BuildContext context,
    required bool isDark,
    required String? dobString,
    required DateTime? tempDOB,
    required bool savingDOB,
    required Future<void> Function() onPickDate,
    required Future<void> Function() onSaveDOB,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditDOBDialog(
        isDark: isDark,
        dobString: dobString,
        tempDOB: tempDOB,
        savingDOB: savingDOB,
        onPickDate: onPickDate,
        onSaveDOB: onSaveDOB,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: ctx.w(24),
          vertical: ctx.h(24),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.modalBackground : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ctx.r(24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ctx.w(40),
              height: ctx.h(4),
              margin: EdgeInsets.only(bottom: ctx.h(20)),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(ctx.r(2)),
              ),
            ),
            ProfileSectionCard(
              title: dobString != null ? 'Personal Info' : 'Set Date of Birth',
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
    );
  }

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
