import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

class Setting extends ChangeNotifier {
  List<String> discountColumns = <String>[];
  List<String> discountColumnOrder = <String>[];
  List<String> salesItemPercentageReportColumns = <String>[];
  List<String> salesItemPercentageReportColumnOrder = <String>[];
  Setting();

  void removeSetting() {
    discountColumns = <String>[];
    discountColumnOrder = <String>[];
    salesItemPercentageReportColumns = <String>[];
    salesItemPercentageReportColumnOrder = <String>[];
    notifyListeners();
  }

  Map tableColumns(tableName) {
    switch (tableName) {
      case 'itemSalesPeriodReport':
        return {
          'item_code': 'Kode Item',
          'item_name': 'Nama Item',
          'supplier_code': 'Kode Supplier',
          'item_type_name': 'Jenis/Departemen',
          'brand_name': 'Merek',
          'discount_percentage': 'Diskon(%)',
          'buy_price': 'Harga Pokok',
          'sell_price': 'Harga Jual',
          'quantity': 'Jumlah',
          'subtotal': 'Subtotal',
          'discount_total': 'Total Diskon',
          'sales_total': 'Total'
        };
      default:
        return {};
    }
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String moneyFormat(var value) {
    if (value is Money) {
      return NumberFormat.currency(locale: "en_US", symbol: value.symbol)
          .format(value.value);
    }
    return NumberFormat.currency(locale: "en_US", symbol: "Rp").format(value);
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }
}
