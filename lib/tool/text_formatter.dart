import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

mixin TextFormatter {
  String timeFormat(TimeDay data) {
    return data.format24Hour();
  }

  String dateFormat(DateTime date) {
    return DateFormat('dd/MM/y', 'id_ID').format(date);
  }

  String datetimeFormat(DateTime data) {
    var formated = DateFormat('dd/MM/y HH:mm');
    return formated.format(data.toUtc());
  }

  String moneyFormat(dynamic value) {
    if (value is Money) {
      return NumberFormat.currency(
              locale: "en_US", symbol: value.symbol, decimalDigits: 1)
          .format(value.value);
    }
    return NumberFormat.currency(
            locale: "en_US", symbol: "Rp", decimalDigits: 1)
        .format(value);
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String dateTimeLocalFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date.toLocal());
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }
}
