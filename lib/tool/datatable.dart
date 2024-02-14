import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class CustomDataTableSource<T extends Model> extends DataTableSource {
  late List<TableColumn> columns;
  late List<T> sortedData;
  String? sortColumn;
  bool isAscending = true;
  Function? actionButtons;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;

  List<T> get selected => selectedMap.values.toList();

  DataCell decorateValue(dynamic cell, TableColumn column) {
    return DataCell(Tooltip(
      message: _formatData(cell),
      triggerMode: TooltipTriggerMode.tap,
      child: _decorateCell(cell),
    ));
  }

  void updateData(index, T model) {
    sortedData[index] = model;
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  Widget _decorateCell(cell) {
    String val = _formatData(cell);
    switch (cell.runtimeType) {
      case Date:
      case DateTime:
        return Align(
          alignment: Alignment.topLeft,
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
          ),
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
        return Align(alignment: Alignment.topLeft, child: Text(val));
    }
  }

  String _formatData(cell) {
    if (cell == null) {
      return '-';
    }
    switch (cell.runtimeType) {
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

  void setData(List<T> rawData) {
    if (paginatorController != null && paginatorController!.isAttached) {
      paginatorController?.goToFirstPage();
    }
    sortedData = rawData;

    sortData(sortColumn ?? columns[0].key, isAscending);
  }

  void sortData(String sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    sortedData.sort((T a, T b) {
      var cellA = a.toMap()[sortColumn] ?? '';
      var cellB = b.toMap()[sortColumn] ?? '';
      return cellA.compareTo(cellB) * (isAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  List<DataCell> decorateModel(model) {
    var jsonData = model.toMap();
    var rows = columns
        .map<DataCell>((column) => decorateValue(jsonData[column.key], column))
        .toList();
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
    T model = sortedData[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedMap.containsKey(index),
      onSelectChanged: (bool? isSelected) {
        if (isSelected == true) {
          selectedMap[index] = model;
        } else {
          selectedMap.remove(index);
        }
        notifyListeners();
      },
      cells: decorateModel(model),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class TableColumn {
  double initX;
  double width;
  double? excelWidth;
  String key;
  String type;
  String name;

  TableColumn(
      {this.initX = 0,
      this.width = 175,
      this.excelWidth,
      this.type = 'string',
      required this.key,
      required this.name});

  bool isNumeric() {
    return ['float', 'decimal', 'int', 'money', 'percentage'].contains(type);
  }
}
