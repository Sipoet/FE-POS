import 'package:dio/dio.dart';
import 'package:fe_pos/model/model.dart';

class SortData {
  String key;
  bool isAscending;
  SortData({required this.key, required this.isAscending});

  @override
  String toString() {
    return "${isAscending ? '' : '-'}$key";
  }
}

enum QueryOperator {
  contains,
  equals,
  not,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  greaterThanOrEqualTo;

  @override
  String toString() {
    switch (this) {
      case contains:
        return 'like';
      case equals:
        return 'eq';
      case not:
        return 'not';
      case lessThan:
        return 'lt';
      case lessThanOrEqualTo:
        return 'lte';
      case greaterThan:
        return 'gt';
      case greaterThanOrEqualTo:
        return 'gte';
    }
  }
}

abstract class FilterData {
  String key;
  FilterData({
    required this.key,
  });

  MapEntry<String, String> toJson();

  String _convertValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Model) {
      return value.id.toString();
    }
    if (value is List) {
      return value.map<String>((e) => _convertValue(e)).join(',');
    }
    return value.toString();
  }
}

class ComparisonFilterData extends FilterData {
  dynamic value;
  QueryOperator operator;
  ComparisonFilterData(
      {required super.key,
      this.operator = QueryOperator.equals,
      required this.value});

  @override
  MapEntry<String, String> toJson() {
    final jsonKey = 'filter[$key][${operator.toString()}]';
    final jsonValue = _convertValue(value);
    return MapEntry(jsonKey, jsonValue);
  }
}

class BetweenFilterData extends FilterData {
  List<dynamic> values;

  BetweenFilterData({required super.key, required this.values});
  @override
  MapEntry<String, String> toJson() {
    final jsonValue =
        values.map<String>((value) => _convertValue(value)).join(',');
    return MapEntry('filter[$key][btw]', jsonValue);
  }
}

class QueryRequest {
  int page;
  int limit;
  List<FilterData> filters;
  List<SortData> sorts;
  CancelToken? cancelToken;
  String? searchText;
  List<String> include;

  QueryRequest(
      {this.page = 1,
      this.limit = 10,
      this.cancelToken,
      this.include = const [],
      this.filters = const [],
      this.sorts = const []});

  Map<String, String?> toQueryParam() {
    Map<String, String?> result = {
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'search_text': searchText,
      'include': include.join(','),
    };
    for (final filter in filters) {
      final entry = filter.toJson();
      result[entry.key] = entry.value;
    }
    result['sort'] = sorts.map((sort) => sort.toString()).join(',');

    return result;
  }
}

class QueryResponse<T> {
  final List<T> models;
  final Map<String, dynamic> metadata;
  const QueryResponse({this.metadata = const {}, this.models = const []});
}
