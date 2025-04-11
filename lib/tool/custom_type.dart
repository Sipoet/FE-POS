import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  DateTime beginningOfDay() {
    return copyWith(
        hour: 0, minute: 0, second: 0, microsecond: 0, millisecond: 0);
  }

  DateTime endOfDay() {
    return add(Duration(days: 1))
        .beginningOfDay()
        .subtract(Duration(milliseconds: 1));
  }

  DateTime beginningOfWeek() {
    int dayT = weekday;
    return subtract(Duration(days: dayT - 1)).beginningOfDay();
  }

  DateTime endOfWeek() {
    int dayT = 7 - weekday;
    return add(Duration(days: dayT)).endOfDay();
  }

  DateTime beginningOfMonth() {
    return DateTime(year, month, 1);
  }

  bool isSameDay(DateTime end) {
    return day == end.day && month == end.month && year == end.year;
  }

  DateTime endOfMonth() {
    if (month == 12) {
      return DateTime(year, month, 31).endOfDay();
    } else {
      return DateTime(year, month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
    }
  }

  Date toDate() {
    return Date.parsingDateTime(this);
  }

  DateTime beginningOfYear() {
    return DateTime(year, 1, 1);
  }

  DateTime endOfYear() {
    return DateTime(year, 12, 31).endOfWeek();
  }
}

extension DateTimeRangeExt on DateTimeRange {
  bool get isSameDay {
    return start.isSameDay(end);
  }
}

class Date extends DateTime {
  Date(
    super.year, [
    super.month = 1,
    super.day = 1,
  ]);
  static Date parse(String value) {
    var datetime = DateTime.parse(value);
    return Date.parsingDateTime(datetime);
  }

  static Date? tryParse(String value) {
    var datetime = DateTime.tryParse(value);
    if (datetime == null) return null;
    return Date.parsingDateTime(datetime);
  }

  static Date today() {
    return parsingDateTime(DateTime.now());
  }

  DateTime toDateTime() {
    return DateTime(year, month, day, 0, 0, 0);
  }

  String format({String pattern = 'dd/MM/y'}) {
    return DateFormat(pattern, 'id_ID').format(this);
  }

  String toJson() {
    return toIso8601String();
  }

  Date beginningOfWeek() {
    int dayT = weekday;
    return subtract(Duration(days: dayT - 1));
  }

  Date endOfWeek() {
    int dayT = 7 - weekday;
    return add(Duration(days: dayT));
  }

  Date beginningOfMonth() {
    return Date(year, month, 1);
  }

  Date endOfMonth() {
    if (month == 12) {
      return Date(year, month, 31);
    } else {
      return Date(year, month + 1, 1).subtract(const Duration(days: 1));
    }
  }

  Date beginningOfYear() {
    return Date(year, 1, 1);
  }

  Date endOfYear() {
    return Date(year, 12, 31);
  }

  @override
  Date subtract(Duration duration) {
    return Date.parsingDateTime(super.subtract(duration));
  }

  @override
  Date add(Duration duration) {
    return Date.parsingDateTime(super.add(duration));
  }

  @override
  String toIso8601String() {
    return '$year-$month-$day';
  }

  static Date parsingDateTime(DateTime value) {
    return Date(value.year, value.month, value.day);
  }
}

class Money {
  final double value;
  final String symbol;
  final double rate;
  const Money(this.value, {this.symbol = 'Rp', this.rate = 1});
  Money operator +(var other) {
    if (other is Money) {
      return Money(value + other.value, symbol: symbol);
    } else {
      return Money(value + other, symbol: symbol);
    }
  }

  static Money parse(value) {
    return Money(double.parse(value));
  }

  static Money? tryParse(value) {
    if (value is double) {
      return Money(value);
    } else if (value is int) {
      return Money(value.toDouble());
    } else if (value is String) {
      var val = double.tryParse(value);
      if (val == null) return null;
      return Money(val);
    } else if (value == null) {
      return null;
    }
    return null;
  }

  String format({int? decimalDigits}) {
    return NumberFormat.currency(
            locale: "id_ID", symbol: symbol, decimalDigits: decimalDigits)
        .format(value);
  }

  @override
  String toString() {
    return value.toString();
  }

  int compareTo(Money other) {
    return value.compareTo(other.value);
  }

  Money operator *(var other) {
    if (other is Money) {
      return Money(value * other.value, symbol: symbol);
    } else {
      return Money(value * other, symbol: symbol);
    }
  }

  @override
  bool operator ==(var other) {
    if (other is Money) {
      return value == other.value;
    } else if (other is double) {
      return value == other;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(value, symbol, rate);

  Money operator /(var other) {
    if (other is Money) {
      return Money(value / other.value, symbol: symbol);
    } else {
      return Money(value / other, symbol: symbol);
    }
  }

  Money operator -(var other) {
    if (other is Money) {
      return Money(value - other.value, symbol: symbol);
    } else {
      return Money(value - other, symbol: symbol);
    }
  }

  bool operator >(var other) {
    if (other is Money) {
      return value > other.value;
    } else {
      return value > other;
    }
  }

  bool operator <(var other) {
    if (other is Money) {
      return value < other.value;
    } else {
      return value < other;
    }
  }

  bool operator <=(var other) {
    if (other is Money) {
      return value <= other.value;
    } else {
      return value <= other;
    }
  }

  bool operator >=(var other) {
    if (other is Money) {
      return value >= other.value;
    } else {
      return value >= other;
    }
  }
}

class Percentage {
  final double value;
  const Percentage(this.value);
  Percentage operator +(var other) {
    if (other is Percentage) {
      return Percentage(value + other.value);
    } else {
      return Percentage(value + other);
    }
  }

  static Percentage parse(String val) {
    val = val.replaceAll(RegExp('%'), '');
    return Percentage(double.parse(val));
  }

  static Percentage? tryParse(String val) {
    val = val.replaceAll(RegExp('%'), '');
    var parsed = double.tryParse(val);
    if (parsed == null) return null;
    return Percentage(parsed);
  }

  @override
  String toString() {
    return ((value * 10000).round() / 100).toString();
  }

  String format() {
    return "${toString()}%";
  }

  bool get isNaN {
    return value.isNaN;
  }

  int compareTo(Percentage other) {
    return value.compareTo(other.value);
  }

  Percentage operator *(var other) {
    if (other is Percentage) {
      return Percentage(value * other.value);
    } else {
      return Percentage(value * other);
    }
  }

  Percentage operator /(var other) {
    if (other is Percentage) {
      return Percentage(value / other.value);
    } else {
      return Percentage(value / other);
    }
  }

  Percentage operator -(var other) {
    if (other is Percentage) {
      return Percentage(value - other.value);
    } else {
      return Percentage(value - other);
    }
  }

  bool operator >(var other) {
    if (other is Percentage) {
      return value > other.value;
    } else {
      return value > other;
    }
  }

  bool operator <(var other) {
    if (other is Percentage) {
      return value < other.value;
    } else {
      return value < other;
    }
  }

  bool operator <=(var other) {
    if (other is Percentage) {
      return value <= other.value;
    } else {
      return value <= other;
    }
  }

  bool operator >=(var other) {
    if (other is Percentage) {
      return value >= other.value;
    } else {
      return value >= other;
    }
  }
}

extension TimeDay on TimeOfDay {
  static TimeOfDay now() {
    final datetime = DateTime.now();
    return TimeOfDay.fromDateTime(datetime);
  }

  String toJson() {
    return format24Hour();
  }

  String format24Hour({bool showSecond = false, String separator = ':'}) {
    List<String> part = [
      hour.toString().padLeft(2, '0'),
      minute.toString().padLeft(2, '0')
    ];
    if (showSecond) {
      part.add('00');
    }
    return part.join(separator);
  }

  static TimeOfDay parse(String value, {String separator = ':'}) {
    final parts = value.split(separator);
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static TimeOfDay? tryParse(String? value, {String separator = ':'}) {
    if (value == null || value.isEmpty) return null;
    try {
      return parse(value, separator: ':');
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
