class Date extends DateTime {
  Date(
    super.year, [
    super.month = 1,
    super.day = 1,
    super.hour = 0,
    super.minute = 0,
    super.second = 0,
    super.millisecond = 0,
    super.microsecond = 0,
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

  @override
  String toIso8601String() {
    final value = super.toIso8601String();
    return value.substring(0, 10);
  }

  static Date parsingDateTime(DateTime value) {
    return Date(value.year, value.month, value.day, value.hour, value.minute,
        value.second, value.millisecond, value.microsecond);
  }
}

class Money {
  final double value;
  final String symbol;
  const Money(this.value, {this.symbol = 'Rp'});
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
    var val = double.tryParse(value);
    if (val == null) return null;
    return Money(val);
  }

  @override
  String toString() {
    return "$symbol ${value.toString()}";
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
    return "${value.toString()}%";
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
