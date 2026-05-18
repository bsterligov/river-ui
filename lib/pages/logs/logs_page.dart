import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../../controllers/time_range_controller.dart';
import '../../widgets/facet_page_layout.dart';
import '../../widgets/log_detail_panel.dart';
import '../../widgets/log_histogram.dart';
import '../../widgets/river_search_bar.dart';
import 'logs_controller.dart';
import 'logs_table.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.apiClient, required this.rangeController});

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late final LogsController _controller;
  final _searchController = TextEditingController();
  final _layoutKey = GlobalKey<FacetPageLayoutState>();

  @override
  void initState() {
    super.initState();
    _controller = LogsController(
      apiClient: widget.apiClient,
      rangeController: widget.rangeController,
    );
    _controller.reload().onError((e, _) => debugPrint('LogsPage: initial reload failed: $e'));
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
        fieldKey: const Key('logs_search'),
        controller: _searchController,
        onSubmit: (v) => _layoutKey.currentState?.onSubmit(v),
        hintText: 'Filter (e.g. service:myapp AND severity:ERROR)',
        errorText: _controller.error,
      ),
      aboveFacetsBuilder: (ctx) => [
        const SizedBox(height: AppLayout.gapL),
        LogHistogram(controller: _controller),
        const SizedBox(height: AppLayout.gapL),
      ],
      contentBuilder: (ctx) => Stack(
        children: [
          _controller.loading
              ? const Center(child: CircularProgressIndicator())
              : LogsTable(controller: _controller),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: LogDetailPanel(controller: _controller),
          ),
        ],
      ),
    );
  }
}
