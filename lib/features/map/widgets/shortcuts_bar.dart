import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/features/map/widgets/map_widgets.dart';

class ShortcutsBar extends StatelessWidget {
  final bool isDark;
  final bool hasRecents;
  final bool hasHome;
  final bool hasWork;
  final List<Map<String, dynamic>> customPins;
  final VoidCallback onRecentsTap;
  final VoidCallback onHomeTap;
  final VoidCallback onWorkTap;
  final Function(Map<String, dynamic>) onCustomPinTap;
  final Function(Map<String, dynamic>) onCustomPinLongPress;
  final VoidCallback onAddTap;

  const ShortcutsBar({
    super.key,
    required this.isDark,
    required this.hasRecents,
    required this.hasHome,
    required this.hasWork,
    required this.customPins,
    required this.onRecentsTap,
    required this.onHomeTap,
    required this.onWorkTap,
    required this.onCustomPinTap,
    required this.onCustomPinLongPress,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: context.h(44),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationChip(
                        type: 'recent',
                        icon: Icons.history_rounded,
                        label: 'Recents',
                        isSet: hasRecents,
                        activeColor: Colors.purple,
                        isDark: isDark,
                        trailingIcon: Icons.arrow_drop_down_rounded,
                        onTap: onRecentsTap,
                      ),
                      SizedBox(width: context.w(8)),
                      LocationChip(
                        type: 'home',
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSet: hasHome,
                        activeColor: Colors.blue,
                        isDark: isDark,
                        onTap: onHomeTap,
                      ),
                      SizedBox(width: context.w(6)),
                      LocationChip(
                        type: 'work',
                        icon: Icons.work_rounded,
                        label: 'Work',
                        isSet: hasWork,
                        activeColor: Colors.orange,
                        isDark: isDark,
                        onTap: onWorkTap,
                      ),
                      ...customPins.map((pin) => Padding(
                            padding: EdgeInsets.only(left: context.w(6)),
                            child: LocationChip(
                              type: 'custom',
                              icon: Icons.place_rounded,
                              label: pin['label'],
                              isSet: true,
                              activeColor: Colors.teal,
                              isDark: isDark,
                              onTap: () => onCustomPinTap(pin),
                              onLongPress: () => onCustomPinLongPress(pin),
                            ),
                          )),
                      SizedBox(width: context.w(6)),
                      AddShortcutButton(isDark: isDark, onTap: onAddTap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
