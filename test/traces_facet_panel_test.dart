import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/traces/traces.dart';
import 'package:ui/controllers/time_range_controller.dart';
import 'package:ui/widgets/top_panel.dart';

// ---------------------------------------------------------------------------
// Fake API helpers
// ---------------------------------------------------------------------------

class _FakeTracesApi extends DefaultApi {
  final List<FacetField> facets;
  final Exception? facetError;
  final List<Map<String, String?>> calls = [];
  int tracesFacetFetchCount = 0;

  _FakeTracesApi({this.facets = const [], this.facetError});

  @override
  Future<List<TraceGroup>?> getTraces(
      {String? filter, String? from, String? to, int? limit}) async {
    calls.add({'filter': filter, 'from': from, 'to': to});
    return [];
  }

  @override
  Future<List<FacetField>?> getTracesFacets(
      {String? filter, String? from, String? to}) async {
    tracesFacetFetchCount++;
    if (facetError != null) throw facetError!;
    return facets;
  }

  @override
  Future<List<FacetField>?> getLogsFacets(
      {String? filter, String? from, String? to}) async => [];

  @override
  Future<List<LogRow>?> getLogs(
      {String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<HistogramBucket>?> getLogsHistogram(
      {String? filter, String? from, String? to, String? step}) async => [];
}

class _HoldingTracesApi extends DefaultApi {
  final Completer<List<FacetField>?> _completer = Completer();

  void complete(List<FacetField> facets) => _completer.complete(facets);

  @override
  Future<List<TraceGroup>?> getTraces(
      {String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<FacetField>?> getTracesFacets(
      {String? filter, String? from, String? to}) => _completer.future;

  @override
  Future<List<FacetField>?> getLogsFacets(
      {String? filter, String? from, String? to}) async => [];

  @override
  Future<List<LogRow>?> getLogs(
      {String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<HistogramBucket>?> getLogsHistogram(
      {String? filter, String? from, String? to, String? step}) async => [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
      'Given the traces page is open and the API returns facets for service_name and operation_name, '
      'When the facet panel finishes loading, '
      'Then service_name and operation_name ExpansionTile groups are visible with value/count rows',
      (tester) async {
    final api = _FakeTracesApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'payment-svc', count: 10)]),
        FacetField(field: 'operation_name', values: [FacetValue(value: 'POST /pay', count: 4)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('service_name'), findsOneWidget);
    expect(find.text('operation_name'), findsOneWidget);
    expect(find.text('payment-svc'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('POST /pay'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets(
      'Given a facet value row is visible, '
      'When the operator taps it, '
      'Then the search bar appends field:value and the trace table re-fetches',
      (tester) async {
    final api = _FakeTracesApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'frontend', count: 5)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final callsBefore = api.calls.length;
    await tester.tap(find.text('frontend'));
    await tester.pumpAndSettle();

    expect(api.calls.length, greaterThan(callsBefore));
    expect(api.calls.last['filter'], equals('service_name:frontend'));
    expect(find.widgetWithText(TextField, 'service_name:frontend'), findsOneWidget);
  });

  testWidgets(
      'Given the /v1/traces/facets request is in flight, '
      'When the panel is rendered, '
      'Then a grey shimmer placeholder is shown',
      (tester) async {
    final api = _HoldingTracesApi();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('facet_shimmer')), findsOneWidget);

    api.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Given the /v1/traces/facets request fails, '
      'When the error is received, '
      'Then the facet panel shows nothing',
      (tester) async {
    final api = _FakeTracesApi(facetError: Exception('network error'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('facet_panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('facet_panel')),
        matching: find.byType(ExpansionTile),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'Given facets have loaded, '
      'When the operator changes the time range, '
      'Then the facet panel re-fetches',
      (tester) async {
    final rc = TimeRangeController();
    final api = _FakeTracesApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc', count: 1)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TopPanel(rangeController: rc),
              Expanded(child: TracesPage(apiClient: api, rangeController: rc)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fetchesAfterInit = api.tracesFacetFetchCount;

    await tester.tap(find.text('Last 1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 15 minutes'));
    await tester.pumpAndSettle();

    expect(api.tracesFacetFetchCount, greaterThan(fetchesAfterInit));
  });
}
