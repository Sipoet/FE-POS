class SortData {
  String key;
  bool isAscending;
  SortData({required this.key, required this.isAscending});
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

class QueryData {
  int page;
  int limit;
  List<FilterData> filters;
  List<SortData> sorts;
  QueryData(
      {this.page = 1,
      this.limit = 10,
      this.filters = const [],
      this.sorts = const []});
}
