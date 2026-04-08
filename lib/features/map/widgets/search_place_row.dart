import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/models/place_result.dart';

/// A single flat row for a search result or history item — Google Maps style.
class SearchPlaceRow extends StatelessWidget {
  final PlaceResult place;
  final bool isHistory;
  final Function(PlaceResult) onTap;

  const SearchPlaceRow({
    super.key,
    required this.place,
    required this.isHistory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final iconBgColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return InkWell(
      onTap: () => onTap(place),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(12),
        ),
        child: Row(
          children: [
            _LeadingIcon(
              isHistory: isHistory,
              bgColor: iconBgColor,
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: _PlaceTextColumn(
                place: place,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final bool isHistory;
  final Color bgColor;

  const _LeadingIcon({required this.isHistory, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.w(40),
      height: context.w(40),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(
        isHistory ? Icons.history_rounded : Icons.location_on_outlined,
        size: context.sp(20),
        color: isHistory ? Colors.grey : Colors.grey[600],
      ),
    );
  }
}

class _PlaceTextColumn extends StatelessWidget {
  final PlaceResult place;
  final Color textColor;
  final Color subtitleColor;

  const _PlaceTextColumn({
    required this.place,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        if (place.address.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            place.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.sp(13),
              color: subtitleColor,
            ),
          ),
        ],
      ],
    );
  }
}
