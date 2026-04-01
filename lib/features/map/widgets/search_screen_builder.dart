import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';
class SearchScreenBuilder {
  static Widget buildBody({
    required BuildContext context,
    required bool isLoading,
    required bool hasSearched,
    required List<PlaceResult> results,
    required List<PlaceResult> history,
    required Color cardColor,
    required Color textColor,
    required Color hintColor,
    required bool isDark,
    required VoidCallback onClearHistory,
    required Function(PlaceResult) onSelectPlace,
    required Function(String) onCategoryTap,
  }) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }
    if (hasSearched) {
      if (results.isEmpty) {
        return _buildNoResults(context, hintColor);
      }
      return _buildResultsList(
          context, results, cardColor, textColor, hintColor, onSelectPlace);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPoiCategories(context, isDark, hintColor, onCategoryTap),
        if (history.isNotEmpty) ...[
          _buildHistoryHeader(context, hintColor, onClearHistory),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(16), vertical: context.h(4)),
              itemCount: history.length,
              separatorBuilder: (_, __) => SizedBox(height: context.h(6)),
              itemBuilder: (context, index) => _placeCard(
                  context,
                  history[index],
                  cardColor,
                  textColor,
                  hintColor,
                  onSelectPlace,
                  isHistory: true),
            ),
          ),
        ] else ...[
          Expanded(child: _buildEmptyState(context, hintColor)),
        ],
      ],
    );
  }
  static Widget _buildNoResults(BuildContext context, Color hintColor) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_off_rounded,
            size: context.sp(64), color: hintColor),
        SizedBox(height: context.h(16)),
        Text('No places found.',
            style: TextStyle(fontSize: context.sp(17), color: hintColor)),
        SizedBox(height: context.h(8)),
        Text('Try a different search term.',
            style: TextStyle(
                fontSize: context.sp(14),
                color: hintColor.withValues(alpha: 0.7))),
      ]),
    );
  }
  static Widget _buildEmptyState(BuildContext context, Color hintColor) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_rounded, size: context.sp(72), color: hintColor),
        SizedBox(height: context.h(16)),
        Text('Where do you want to go?',
            style: TextStyle(
                fontSize: context.sp(18),
                color: hintColor,
                fontWeight: FontWeight.w500)),
        SizedBox(height: context.h(8)),
        Text('Search for a place or select\na category above',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.sp(14),
                color: hintColor.withValues(alpha: 0.7))),
      ]),
    );
  }
  static Widget _buildHistoryHeader(
      BuildContext context, Color hintColor, VoidCallback onClear) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.w(20), context.h(16), context.w(12), context.h(8)),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: context.sp(18), color: hintColor),
          SizedBox(width: context.w(8)),
          Text('Recent',
              style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: hintColor)),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(12), vertical: context.h(4))),
            child: Text('Clear', style: TextStyle(fontSize: context.sp(13))),
          ),
        ],
      ),
    );
  }
  static Widget _buildPoiCategories(BuildContext context, bool isDark,
      Color hintColor, Function(String) onCategoryTap) {
    final categories = [
      {
        'icon': Icons.restaurant_rounded,
        'label': 'Restaurant',
        'query': 'restaurant'
      },
      {
        'icon': Icons.local_gas_station_rounded,
        'label': 'Gas Station',
        'query': 'gas station'
      },
      {
        'icon': Icons.local_parking_rounded,
        'label': 'Parking',
        'query': 'parking'
      },
      {'icon': Icons.hotel_rounded, 'label': 'Hotel', 'query': 'hotel'},
      {
        'icon': Icons.shopping_bag_rounded,
        'label': 'Shopping',
        'query': 'shopping mall'
      },
      {
        'icon': Icons.local_hospital_rounded,
        'label': 'Hospital',
        'query': 'hospital'
      },
    ];
    return SizedBox(
      height: context.h(115),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: context.w(16), vertical: context.h(12)),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => onCategoryTap(cat['query'] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(14)),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(cat['icon'] as IconData,
                      color: Colors.blueAccent, size: context.sp(24)),
                ),
                SizedBox(height: context.h(6)),
                Text(cat['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.sp(11),
                        color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }
  static Widget _buildResultsList(
      BuildContext context,
      List<PlaceResult> results,
      Color cardColor,
      Color textColor,
      Color hintColor,
      Function(PlaceResult) onSelect) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
          vertical: context.h(12), horizontal: context.w(16)),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(8)),
      itemBuilder: (context, index) => _placeCard(
          context, results[index], cardColor, textColor, hintColor, onSelect),
    );
  }
  static Widget _placeCard(
      BuildContext context,
      PlaceResult place,
      Color cardColor,
      Color textColor,
      Color hintColor,
      Function(PlaceResult) onSelect,
      {bool isHistory = false}) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(context.r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(16)),
        onTap: () => onSelect(place),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.w(16), vertical: context.h(14)),
          child: Row(children: [
            Container(
              width: context.w(44),
              height: context.h(44),
              decoration: BoxDecoration(
                color: (isHistory ? Colors.grey : Colors.redAccent)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  isHistory ? Icons.history_rounded : Icons.location_pin,
                  color: isHistory ? Colors.grey : Colors.redAccent,
                  size: context.sp(22)),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  if (place.address.isNotEmpty) ...[
                    SizedBox(height: context.h(3)),
                    Text(place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.sp(13),
                            color: textColor.withValues(alpha: 0.55))),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            Icon(Icons.arrow_forward_ios_rounded,
                size: context.sp(14), color: textColor.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }
}
