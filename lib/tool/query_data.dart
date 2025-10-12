class SortData {
  String key;
  bool isAscending;
  SortData({required this.key, required this.isAscending});
}

enum Operator {
  contains,
  equals,
  not,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  between,
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
      case between:
        return 'btw';
    }
  }
}

class FilterData {
  String key;
  Operator operator;
  String value;
  FilterData(
      {required this.key,
      this.operator = Operator.equals,
      required this.value});
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
