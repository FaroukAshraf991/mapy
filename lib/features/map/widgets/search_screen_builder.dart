import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
import 'package:mapy/features/map/widgets/search_place_row.dart';

/// Builds the body of the search screen — Google Maps flat-list style.
class SearchScreenBuilder {
  static Widget buildBody({
    required BuildContext context,
    required bool isLoading,
    required bool hasSearched,
    required List<PlaceResult> results,
    required List<PlaceResult> history,
    required bool isDark,
    required VoidCallback onShowAllHistory,
    required Function(PlaceResult) onSelectPlace,
  }) {
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    }

    if (hasSearched) {
      return results.isEmpty
          ? _NoResults(isDark: isDark)
          : _ResultsList(
              results: results,
              dividerColor: dividerColor,
              onSelect: onSelectPlace,
            );
    }

    return history.isEmpty
        ? const SizedBox.shrink()
        : _HistorySection(
            history: history,
            dividerColor: dividerColor,
            onSelect: onSelectPlace,
            onShowAll: onShowAllHistory,
          );
  }
}

// ─── Recent History Section ──────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<PlaceResult> history;
  final Color dividerColor;
  final Function(PlaceResult) onSelect;
  final VoidCallback onShowAll;

  const _HistorySection({
    required this.history,
    required this.dividerColor,
    required this.onSelect,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecentHeader(labelColor: labelColor),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: history.length + 1,
            separatorBuilder: (_, i) =>
                i < history.length - 1 ? Divider(height: 1, color: dividerColor, indent: context.w(72)) : const SizedBox.shrink(),
            itemBuilder: (ctx, i) {
              if (i == history.length) {
                return _MoreHistoryButton(onShowAll: onShowAll);
              }
              return SearchPlaceRow(
                place: history[i],
                isHistory: true,
                onTap: onSelect,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentHeader extends StatelessWidget {
  final Color labelColor;

  const _RecentHeader({required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.w(16), context.h(16), context.w(12), context.h(8)),
      child: Row(
        children: [
          Text(
            'Recent',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const Spacer(),
          Icon(Icons.info_outline_rounded, size: context.sp(18), color: labelColor),
        ],
      ),
    );
  }
}

class _MoreHistoryButton extends StatelessWidget {
  final VoidCallback onShowAll;

  const _MoreHistoryButton({required this.onShowAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Center(
        child: TextButton(
          onPressed: onShowAll,
          child: Text(
            'More from recent history',
            style: TextStyle(
              fontSize: context.sp(14),
              color: Colors.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search Results Section ───────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<PlaceResult> results;
  final Color dividerColor;
  final Function(PlaceResult) onSelect;

  const _ResultsList({
    required this.results,
    required this.dividerColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: dividerColor, indent: context.w(72)),
      itemBuilder: (ctx, i) => SearchPlaceRow(
        place: results[i],
        isHistory: false,
        onTap: onSelect,
      ),
    );
  }
}

// ─── No Results ───────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final bool isDark;

  const _NoResults({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hintColor = isDark ? Colors.white38 : Colors.black26;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: context.sp(52), color: hintColor),
          SizedBox(height: context.h(12)),
          Text(
            'No results found',
            style: TextStyle(fontSize: context.sp(16), color: hintColor),
          ),
        ],
      ),
    );
  }
}
