import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/facet_page_layout.dart';
import '../../widgets/river_search_bar.dart';
import 'trace_detail_panel.dart';
import 'traces_controller.dart';
import 'traces_table.dart';

class TracesPage extends StatefulWidget {
  const TracesPage({
    super.key,
    required this.apiClient,
    required this.rangeController,
  });

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  @override
  State<TracesPage> createState() => _TracesPageState();
}

class _TracesPageState extends State<TracesPage> {
  late final TracesController _controller;
  final _searchController = TextEditingController();
  final _layoutKey = GlobalKey<FacetPageLayoutState>();

  @override
  void initState() {
    super.initState();
    _controller = TracesController(
      apiClient: widget.apiClient,
      rangeController: widget.rangeController,
    );
    _controller.reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacetPageLayout(
      key: _layoutKey,
      controller: _controller,
      searchController: _searchController,
      filterBarBuilder: (ctx) => FilterBar(
        fieldKey: const Key('traces_search'),
        controller: _searchController,
        onSubmit: (v) => _layoutKey.currentState?.onSubmit(v),
        hintText: 'Filter (e.g. service:myapp AND operation:GET)',
        errorText: _controller.error,
      ),
      aboveFacetsBuilder: (ctx) => const [SizedBox(height: AppLayout.gapL)],
      contentBuilder: (ctx) => Stack(
        children: [
          _controller.loading
              ? const Center(child: CircularProgressIndicator())
              : TracesTable(controller: _controller),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: TraceDetailPanel(controller: _controller),
          ),
        ],
      ),
    );
  }
}
