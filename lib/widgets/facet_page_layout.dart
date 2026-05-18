import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'collapsible_facet_panel.dart';
import 'facet_data_source.dart';
import 'facet_panel.dart';

/// Shared layout for pages that have a collapsible facet panel on the left
/// and a scrollable content area on the right.
///
/// Owns [_manualFilter] and [_facetExpanded] state so neither [LogsPage] nor
/// [TracesPage] need to duplicate that logic.
class FacetPageLayout extends StatefulWidget {
  const FacetPageLayout({
    super.key,
    required this.controller,
    required this.searchController,
    required this.filterBarBuilder,
    required this.aboveFacetsBuilder,
    required this.contentBuilder,
  });

  final FacetDataSource controller;
  final TextEditingController searchController;

  /// Builds the filter bar — called inside [ListenableBuilder] so it always
  /// sees the latest controller state (e.g. [error]).
  final WidgetBuilder filterBarBuilder;

  /// Builds optional widgets between the filter bar and the facet+content row
  /// (e.g. log histogram). Return an empty list if none.
  final List<Widget> Function(BuildContext) aboveFacetsBuilder;

  /// Builds the main content area to the right of the facet panel — called
  /// inside [ListenableBuilder] so it sees the latest [loading] / [error].
  final WidgetBuilder contentBuilder;

  @override
  State<FacetPageLayout> createState() => FacetPageLayoutState();
}

class FacetPageLayoutState extends State<FacetPageLayout> {
  String _manualFilter = '';
  bool _facetExpanded = true;

  void onSubmit(String value) {
    setState(() => _manualFilter = value);
    widget.controller.setFilter(value);
    widget.controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final facetPanel = FacetPanel(
      controller: widget.controller,
      searchController: widget.searchController,
      manualFilter: _manualFilter,
      expanded: _facetExpanded,
      onToggle: () => setState(() => _facetExpanded = !_facetExpanded),
    );
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.filterBarBuilder(context),
          ...widget.aboveFacetsBuilder(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CollapsibleFacetPanel(expanded: _facetExpanded, child: child!),
                const SizedBox(width: AppLayout.gapL),
                Expanded(child: widget.contentBuilder(context)),
              ],
            ),
          ),
        ],
      ),
      child: facetPanel,
    );
  }
}
