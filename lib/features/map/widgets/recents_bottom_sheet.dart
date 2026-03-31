import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';

class RecentsBottomSheet extends StatelessWidget {
  final List<PlaceResult> history;
  final bool isDark;
  final Function(PlaceResult) onSelect;
  final VoidCallback onClear;

  const RecentsBottomSheet({
    super.key,
    required this.history,
    required this.isDark,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(32))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(-5)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(32))),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin:
                    EdgeInsets.only(top: context.h(12), bottom: context.h(8)),
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(context.r(2)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(24), vertical: context.h(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Locations',
                      style: TextStyle(
                        fontSize: context.sp(22),
                        fontWeight: FontWeight.w900,
                        color:
                            isDark ? Colors.white : AppConstants.darkBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton(
                        onPressed: onClear,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (history.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(60)),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded,
                          size: context.sp(48),
                          color: isDark ? Colors.white12 : Colors.black12),
                      SizedBox(height: context.h(16)),
                      Text(
                        'No recent searches',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: context.sp(16),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: context.h(8)),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final place = history[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: context.w(24), vertical: context.h(4)),
                        leading: Container(
                          padding: EdgeInsets.all(context.w(8)),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.history_rounded,
                              color: Colors.purple, size: context.sp(20)),
                        ),
                        title: Text(
                          place.shortName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppConstants.darkBackground,
                          ),
                        ),
                        subtitle: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: context.sp(12),
                          ),
                        ),
                        onTap: () => onSelect(place),
                      );
                    },
                  ),
                ),
              SizedBox(height: context.h(32)),
            ],
          ),
        ),
      ),
    );
  }
}
