import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// Google Maps–style "More" bottom sheet showing saved custom pins.
class MoreShortcutsSheet extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> customPins;
  final Function(Map<String, dynamic>) onPinTap;
  final Function(Map<String, dynamic>) onPinLongPress;
  final VoidCallback onAddTap;

  const MoreShortcutsSheet({
    super.key,
    required this.isDark,
    required this.customPins,
    required this.onPinTap,
    required this.onPinLongPress,
    required this.onAddTap,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDark,
    required List<Map<String, dynamic>> customPins,
    required Function(Map<String, dynamic>) onPinTap,
    required Function(Map<String, dynamic>) onPinLongPress,
    required VoidCallback onAddTap,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MoreShortcutsSheet(
        isDark: isDark,
        customPins: customPins,
        onPinTap: onPinTap,
        onPinLongPress: onPinLongPress,
        onAddTap: onAddTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(16))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(isDark: isDark),
          _SheetHeader(textColor: textColor),
          Divider(height: 1, color: dividerColor),
          if (customPins.isEmpty)
            _EmptyState(subtitleColor: subtitleColor)
          else
            _PinList(
              customPins: customPins,
              textColor: textColor,
              subtitleColor: subtitleColor,
              dividerColor: dividerColor,
              onPinTap: onPinTap,
              onPinLongPress: onPinLongPress,
            ),
          _AddPlaceButton(onTap: onAddTap),
          SizedBox(height: context.h(16)),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(10)),
      child: Container(
        width: context.w(36),
        height: context.h(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(context.r(4)),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final Color textColor;
  const _SheetHeader({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.w(16), context.h(4), context.w(16), context.h(12)),
      child: Row(
        children: [
          Text(
            'Saved places',
            style: TextStyle(
              fontSize: context.sp(16),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinList extends StatelessWidget {
  final List<Map<String, dynamic>> customPins;
  final Color textColor;
  final Color subtitleColor;
  final Color dividerColor;
  final Function(Map<String, dynamic>) onPinTap;
  final Function(Map<String, dynamic>) onPinLongPress;

  const _PinList({
    required this.customPins,
    required this.textColor,
    required this.subtitleColor,
    required this.dividerColor,
    required this.onPinTap,
    required this.onPinLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: customPins.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: dividerColor, indent: context.w(64)),
      itemBuilder: (_, i) => _PinRow(
        pin: customPins[i],
        textColor: textColor,
        subtitleColor: subtitleColor,
        onTap: onPinTap,
        onLongPress: onPinLongPress,
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  final Map<String, dynamic> pin;
  final Color textColor;
  final Color subtitleColor;
  final Function(Map<String, dynamic>) onTap;
  final Function(Map<String, dynamic>) onLongPress;

  const _PinRow({
    required this.pin,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(pin),
      onLongPress: () => onLongPress(pin),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(12)),
        child: Row(
          children: [
            Container(
              width: context.w(40),
              height: context.w(40),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_rounded,
                  size: context.sp(20), color: Colors.teal),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Text(
                pin['label'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.sp(15),
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color subtitleColor;
  const _EmptyState({required this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(24)),
      child: Text(
        'No saved places yet',
        style: TextStyle(fontSize: context.sp(14), color: subtitleColor),
      ),
    );
  }
}

class _AddPlaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(14)),
        child: Row(
          children: [
            Container(
              width: context.w(40),
              height: context.w(40),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: context.sp(22), color: Colors.grey),
            ),
            SizedBox(width: context.w(14)),
            Text(
              'Add a place',
              style: TextStyle(
                fontSize: context.sp(15),
                color: Colors.teal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
