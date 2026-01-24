import 'package:dio/dio.dart';
import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';

class SortData {
  String key;
  bool isAscending;
  SortData({required this.key, required this.isAscending});

  @override
  String toString() {
    return "${isAscending ? '' : '-'}$key";
  }

  // @override
  // bool operator ==(other) {
  //   if (other is SortData) {
  //     other.toString() == toString();
  //   }
  //   return false;
  // }
}

enum QueryOperator implements EnumTranslation {
  contains,
  equals,
  not,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  greaterThanOrEqualTo,
  between;

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
      case between:
        return 'btw';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case equals:
        return '=';
      case contains:
        return 'Mengandung';
      case not:
        return 'bukan';
      case lessThan:
        return 'lebih kecil dari';
      case lessThanOrEqualTo:
        return 'lebih kecil atau sama dengan';
      case greaterThan:
        return 'lebih besar dari';
      case greaterThanOrEqualTo:
        return 'lebih besar atau sama dengan';
      case between:
        return 'antara';
    }
  }

  String shortName() {
    switch (this) {
      case equals:
        return '=';
      case contains:
        return 'ilike';
      case not:
        return 'not';
      case lessThan:
        return '<';
      case lessThanOrEqualTo:
        return '<=';
      case greaterThan:
        return '>';
      case greaterThanOrEqualTo:
        return '>=';
      case between:
        return '<=>';
    }
  }
}

abstract class FilterData {
  String key;
  FilterData({required this.key});

  MapEntry<String, String> toEntryJson();

  String _convertValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is DateTime || value is Date) {
      return value.toIso8601String();
    }
    if (value is TimeOfDay) {
      return value.format24Hour();
    }
    if (value is Percentage) {
      return value.value.toString();
    }
    if (value is Money) {
      return value.value.toString();
    }
    if (value is Model) {
      return value.id.toString();
    }
    if (value is List) {
      return value.map<String>((e) => _convertValue(e)).join(',');
    }
    return value.toString();
  }

  String get decoratedValue;
}

class ComparisonFilterData extends FilterData {
  dynamic value;
  QueryOperator operator;
  ComparisonFilterData({
    required super.key,
    this.operator = QueryOperator.equals,
    required this.value,
  });

  @override
  MapEntry<String, String> toEntryJson() {
    final jsonKey = 'filter[$key][${operator.toString()}]';
    final jsonValue = _convertValue(value);
    return MapEntry(jsonKey, jsonValue);
  }

  @override
  String get decoratedValue => value.toString();
}

class BetweenFilterData extends FilterData {
  List<dynamic> values;

  BetweenFilterData({required super.key, required this.values});
  @override
  MapEntry<String, String> toEntryJson() {
    final jsonValue = values
        .map<String>((value) => _convertValue(value))
        .join(',');
    return MapEntry('filter[$key][btw]', jsonValue);
  }

  @override
  String get decoratedValue =>
      values.map<String>((e) => e.toString()).join(' - ');
}

class QueryRequest {
  int page;
  int? limit;
  List<FilterData> filters;
  List<SortData> sorts;
  List<String> fields;
  CancelToken? cancelToken;
  String searchText;
  Set<String> _include;

  QueryRequest({
    this.page = 1,
    this.limit,
    this.cancelToken,
    this.searchText = '',
    List<String>? fields,
    List<String>? include,
    List<FilterData>? filters,
    List<SortData>? sorts,
  }) : _include = (include ?? []).toSet(),
       filters = filters ?? [],
       sorts = sorts ?? [],
       fields = fields ?? [];

  Map<String, String?> toQueryParam() {
    Map<String, String?> result = {
      'page[page]': page.toString(),
      if (limit != null) 'page[limit]': limit.toString(),
      'search_text': searchText,
      'field': fields.join(','),
      'include': _include.join(','),
    };
    for (final filter in filters) {
      final entry = filter.toEntryJson();
      result[entry.key] = entry.value;
    }
    result['sort'] = sorts.map((sort) => sort.toString()).join(',');

    return result;
  }

  set include(List<String> value) => _include = value.toSet();
  List<String> get include => _include.toList();

  void includeAdd(String value) {
    _include.add(value);
  }

  void includeAddAll(List<String> value) {
    _include.addAll(value);
  }
}

class QueryResponse<T> {
  final List<T> models;
  final Map<String, dynamic> metadata;
  const QueryResponse({this.metadata = const {}, this.models = const []});
}
