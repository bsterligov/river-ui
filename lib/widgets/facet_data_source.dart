import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

abstract class FacetDataSource implements Listenable {
  String get filter;
  DateTime get from;
  DateTime get to;
  int get rangeVersion;
  DefaultApi get apiClient;

  void setFilter(String value);
  Future<void> reload();

  Future<List<FacetField>?> fetchFacets({
    String? filter,
    String? from,
    String? to,
  });
}
