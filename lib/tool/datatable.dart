import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class CustomDataTableSource<T extends Model> extends DataTableSource {
  late List<TableColumn> columns;
  late List<T> sortedData = [];
  TableColumn? sortColumn;
  bool isAscending = true;
  List<Widget> Function(T model, int index)? actionButtons;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;
  bool isShowActions = false;
  List<T> get selected => selectedMap.values.toList();

  DataCell decorateValue(jsonData, TableColumn column) {
    final cell = jsonData[column.attributeKey];
    final val = _formatData(cell);
    return DataCell(Tooltip(
      message: val,
      triggerMode: TooltipTriggerMode.longPress,
      child: _decorateCell(val, column.type),
    ));
  }

  void setActionButtons(value) {
    actionButtons = value;
  }

  void updateData(index, T model) {
    sortedData[index] = model;
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  Widget _decorateCell(String val, String columnType) {
    switch (columnType) {
      // case 'image':
      // return Image.network('assets/${val}')
      // case 'link':
      case 'date':
      case 'datetime':
        return Align(
          alignment: Alignment.topLeft,
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'money':
      case 'double':
      case 'decimal':
      case 'integer':
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
      case const (Date):
        return _dateFormat(cell);
      case const (DateTime):
        return _datetimeFormat(cell);
      case const (TimeOfDay):
        return _timeFormat(cell);
      case const (Money):
        return _moneyFormat(cell);
      case const (double):
      case const (int):
        return _numberFormat(cell);
      case const (String):
        return cell;
      default:
        try {
          return cell.humanize();
        } catch (error) {
          return cell.toString();
        }
    }
  }

  static String _timeFormat(TimeOfDay data) {
    var formated = NumberFormat("00", "en_US");
    return "${formated.format(data.hour)}:${formated.format(data.minute)}";
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

    sortData(sortColumn ?? columns[0], isAscending);
  }

  void sortData(TableColumn sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    sortedData.sort((T a, T b) {
      var cellA = a.toMap()[sortColumn.attributeKey] ?? '';
      var cellB = b.toMap()[sortColumn.attributeKey] ?? '';
      return cellA.compareTo(cellB) * (isAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  List<DataCell> decorateModel(T model, int index) {
    var jsonData = model.toMap();
    var rows = columns
        .map<DataCell>((column) => decorateValue(jsonData, column))
        .toList();
    if (actionButtons != null) {
      rows.add(DataCell(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: actionButtons!(model, index),
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
      cells: decorateModel(model, index),
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
  String? path;
  String attributeKey;
  String sortKey;
  bool canSort;

  TableColumn(
      {this.initX = 0,
      this.width = 175,
      this.excelWidth,
      this.path,
      required this.attributeKey,
      this.type = 'string',
      this.canSort = true,
      required this.sortKey,
      required this.key,
      required this.name});

  bool isNumeric() {
    return ['float', 'decimal', 'int', 'money', 'percentage'].contains(type);
  }
}
