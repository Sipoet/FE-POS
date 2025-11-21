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

  String humanize() {
    switch (this) {
      case contains:
        return 'contain';
      case equals:
        return '=';
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
    }
  }

  static QueryOperator fromString(text) {
    switch (text) {
      case 'like':
        return contains;
      case 'contains':
        return contains;
      case 'eq':
        return equals;
      case '=':
        return equals;
      case ':':
        return equals;
      case 'not':
        return not;
      case '<':
        return lessThan;
      case 'lt':
        return lessThan;
      case '<=':
        return lessThanOrEqualTo;
      case 'lte':
        return lessThanOrEqualTo;
      case '>':
        return greaterThan;
      case 'gt':
        return greaterThan;
      case '>=':
        return greaterThanOrEqualTo;
      case 'gte':
        return greaterThanOrEqualTo;
      default:
        throw 'invalid query operator $text';
    }
  }
}

abstract class FilterData {
  String key;
  FilterData({
    required this.key,
  });

  String get humanizeValue;
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
  QueryOperator queryOperator;
  ComparisonFilterData(
      {required super.key,
      this.queryOperator = QueryOperator.equals,
      required this.value});
  @override
  String get humanizeValue => value.toString();
  @override
  MapEntry<String, String> toJson() {
    final jsonKey = 'filter[$key][${queryOperator.toString()}]';
    final jsonValue = _convertValue(value);
    return MapEntry(jsonKey, jsonValue);
  }
}

class BetweenFilterData extends FilterData {
  List<dynamic> values;

  BetweenFilterData({required super.key, required this.values});
  @override
  String get humanizeValue => values.map<String>((e) => e.toString()).join('-');
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
