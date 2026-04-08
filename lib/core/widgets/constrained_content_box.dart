import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// Centers [child] and clamps its width to [maxWidth].
/// Defaults to [context.maxContentWidth], which resolves to [double.infinity]
/// on mobile — making this widget a zero-cost pass-through on phones.
class ConstrainedContentBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ConstrainedContentBox({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxWidth ?? context.maxContentWidth;
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
