import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CollapsibleFacetPanel extends StatelessWidget {
  const CollapsibleFacetPanel({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  static const _collapsedWidth = AppLayout.collapsedFacetPanelWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppLayout.radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? AppLayout.facetPanelWidth : _collapsedWidth,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: AppLayout.facetPanelWidth,
          maxWidth: AppLayout.facetPanelWidth,
          child: child,
        ),
      ),
    );
  }
}
