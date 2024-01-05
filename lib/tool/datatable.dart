import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Datatable extends DataTableSource {
  late List<Model> sortedData;
  late List<String> keys;
  Function? actionButtons;

  DataCell decorateValue(cell) {
    switch (cell.runtimeType) {
      case Null:
        return const DataCell(Text('-'));
      case Date:
        String val = _dateFormat(cell);
        return DataCell(SelectableText(val));
      case DateTime:
        String val = _datetimeFormat(cell);
        return DataCell(SelectableText(val));
      case Money:
        String val = _moneyFormat(cell);
        return DataCell(Align(
            alignment: Alignment.centerRight, child: SelectableText(val)));
      case double:
      case int:
        String val = _numberFormat(cell);
        return DataCell(Align(
            alignment: Alignment.centerRight, child: SelectableText(val)));
      default:
        return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _dateFormat(DateTime data) {
    var formated = DateFormat('dd/MM/y');
    return formated.format(data);
  }

  static String _datetimeFormat(DateTime data) {
    var formated = DateFormat('dd/MM/y HH:mm');
    return formated.format(data.toUtc());
  }

  static String _moneyFormat(number) {
    return NumberFormat.currency(locale: "en_US", symbol: number.symbol)
        .format(number.value);
  }

  static String _numberFormat(number) {
    var formated = NumberFormat(",##0.##", "en_US");
    return formated.format(number);
  }

  void setData(List<Model> rawData, String sortColumn, bool sortAscending) {
    sortedData = rawData;
    sortData(sortColumn, sortAscending);
  }

  void setKeys(List<String> keys) {
    this.keys = keys;
  }

  void sortData(String sortColumn, bool sortAscending) {
    sortedData.sort((Model a, Model b) {
      var cellA = a.toMap()[sortColumn] ?? '';
      var cellB = b.toMap()[sortColumn] ?? '';
      return cellA.compareTo(cellB) * (sortAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  List<DataCell> decorateModel(model) {
    var jsonData = model.toMap();
    var rows =
        keys.map<DataCell>((key) => decorateValue(jsonData[key])).toList();
    if (actionButtons != null) {
      rows.add(DataCell(Row(
        children: actionButtons!(model),
      )));
    }
    return rows;
  }

  @override
  DataRow? getRow(int index) {
    Model model = sortedData[index];
    return DataRow.byIndex(
      index: index,
      cells: decorateModel(model),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
