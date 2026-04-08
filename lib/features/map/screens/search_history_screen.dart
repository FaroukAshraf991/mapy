import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/services/search_history_service.dart';

/// Full search history screen — shows all past searches, supports
/// individual deletion and clear-all. Pops with [PlaceResult] on selection.
class SearchHistoryScreen extends StatefulWidget {
  final List<PlaceResult> initialHistory;

  const SearchHistoryScreen({super.key, required this.initialHistory});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  late List<PlaceResult> _history;

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.initialHistory);
  }

  Future<void> _deleteItem(PlaceResult place) async {
    setState(() => _history.remove(place));
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    // Re-save the updated list to Supabase
    final updated = List<PlaceResult>.from(widget.initialHistory)
      ..remove(place);
    await SearchHistoryService.replaceHistory(uid, updated);
  }

  Future<void> _clearAll() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) await SearchHistoryService.clearHistory(uid);
    if (!mounted) return;
    setState(() => _history = []);
  }

  void _selectPlace(PlaceResult place) {
    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _HistoryAppBar(
        isDark: isDark,
        textColor: textColor,
        hasItems: _history.isNotEmpty,
        onClearAll: _clearAll,
      ),
      body: _history.isEmpty
          ? _EmptyHistory(isDark: isDark)
          : _HistoryList(
              history: _history,
              dividerColor: dividerColor,
              onSelect: _selectPlace,
              onDelete: _deleteItem,
            ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final Color textColor;
  final bool hasItems;
  final VoidCallback onClearAll;

  const _HistoryAppBar({
    required this.isDark,
    required this.textColor,
    required this.hasItems,
    required this.onClearAll,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? AppConstants.darkBackground : AppConstants.lightBackground;
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      foregroundColor: textColor,
      title: Text('Search history',
          style: TextStyle(fontSize: context.sp(17), color: textColor)),
      actions: [
        if (hasItems)
          TextButton(
            onPressed: onClearAll,
            child: Text('Clear all',
                style: TextStyle(
                    fontSize: context.sp(14), color: Colors.redAccent)),
          ),
      ],
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<PlaceResult> history;
  final Color dividerColor;
  final Function(PlaceResult) onSelect;
  final Function(PlaceResult) onDelete;

  const _HistoryList({
    required this.history,
    required this.dividerColor,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: history.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: dividerColor, indent: context.w(72)),
      itemBuilder: (_, i) => _HistoryRow(
        place: history[i],
        textColor: textColor,
        subtitleColor: subtitleColor,
        iconBg: iconBg,
        onTap: onSelect,
        onDelete: onDelete,
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final PlaceResult place;
  final Color textColor;
  final Color subtitleColor;
  final Color iconBg;
  final Function(PlaceResult) onTap;
  final Function(PlaceResult) onDelete;

  const _HistoryRow({
    required this.place,
    required this.textColor,
    required this.subtitleColor,
    required this.iconBg,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(place),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(12)),
        child: Row(
          children: [
            Container(
              width: context.w(40),
              height: context.w(40),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded,
                  size: context.sp(20), color: Colors.grey),
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  if (place.address.isNotEmpty) ...[
                    SizedBox(height: context.h(2)),
                    Text(place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.sp(13), color: subtitleColor)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  size: context.sp(18), color: subtitleColor),
              onPressed: () => onDelete(place),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final bool isDark;
  const _EmptyHistory({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hintColor = isDark ? Colors.white38 : Colors.black26;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_rounded, size: context.sp(52), color: hintColor),
        SizedBox(height: context.h(12)),
        Text('No search history',
            style: TextStyle(fontSize: context.sp(16), color: hintColor)),
      ]),
    );
  }
}
