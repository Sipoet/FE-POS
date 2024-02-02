import 'dart:ffi';

import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Datatable extends DataTableSource {
  late List<Model> sortedData;
  late List<String> keys;
  late Map<String, ColumnDetail> columnDetails = {};
  Function? actionButtons;

  DataCell decorateValue(cell, key) {
    var columnDetail = columnDetails[key] ?? ColumnDetail(initX: 0, width: 150);
    return DataCell(Tooltip(
      message: _formatData(cell),
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(width: columnDetail.width, child: _decorateCell(cell)),
    ));
  }

  Widget _decorateCell(cell) {
    String val = _formatData(cell);
    switch (cell.runtimeType) {
      case Void:
      case Date:
      case DateTime:
        return Text(
          val,
          overflow: TextOverflow.ellipsis,
        );
      case Money:
      case double:
      case int:
        return Align(
            alignment: Alignment.centerRight,
            child: Text(
              val,
              overflow: TextOverflow.ellipsis,
            ));
      default:
        return Text(val);
    }
  }

  String _formatData(cell) {
    switch (cell.runtimeType) {
      case Void:
        return '-';
      case Date:
        return _dateFormat(cell);
      case DateTime:
        return _datetimeFormat(cell);
      case Money:
        return _moneyFormat(cell);
      case double:
      case int:
        return _numberFormat(cell);
      default:
        return cell.toString();
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

  void setData(
    List<Model> rawData,
    String sortColumn,
    bool sortAscending,
  ) {
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
        keys.map<DataCell>((key) => decorateValue(jsonData[key], key)).toList();
    if (actionButtons != null) {
      rows.add(DataCell(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
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

class ColumnDetail {
  double initX;
  double width;
  ColumnDetail({required this.initX, required this.width});
}
