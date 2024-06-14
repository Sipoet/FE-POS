import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

extension ComparingTimeOfDay on TimeOfDay {
  int compareTo(TimeOfDay val2) {
    return toString().compareTo(val2.toString());
  }
}

class ResponseResult<T> {
  int totalPages;
  int? totalRows;
  List<T> models;
  ResponseResult({this.totalPages = 0, this.totalRows, required this.models});
}

class CustomAsyncDataTableSource<T extends Model> extends AsyncDataTableSource
    with TableDecorator<T> {
  final List<TableColumn> columns;
  late List<T> sortedData = [];
  TableColumn? sortColumn;
  bool isAscending = true;
  List<Widget> Function(T model, int index)? actionButtons;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;
  bool isShowActions = false;
  List<T> get selected => selectedMap.values.toList();
  int totalRows = 0;

  Future<ResponseResult<T>> Function(
      {int page,
      int limit,
      TableColumn sortColumn,
      bool isAscending}) fetchData;

  CustomAsyncDataTableSource(
      {required this.fetchData,
      this.isShowActions = false,
      this.isAscending = true,
      this.sortColumn,
      required this.columns,
      this.actionButtons,
      this.paginatorController});

  void refreshDataFromFirstPage() {
    if (paginatorController?.isAttached ?? false) {
      paginatorController?.goToFirstPage();
    }
    refreshDatasource();
  }

  bool get hasActionButton => actionButtons is Function;

  void sortData(TableColumn sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    refreshDatasource();
  }

  @override
  int get rowCount => totalRows;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) {
    final page = startIndex ~/ count + 1;
    return fetchData(
            page: page,
            limit: count,
            isAscending: this.isAscending,
            sortColumn: this.sortColumn ?? this.columns[0])
        .then((responseResult) {
      totalRows =
          responseResult.totalRows ?? (responseResult.totalPages * count);
      List<DataRow> rows = [];
      for (T model in responseResult.models) {
        rows.add(DataRow(
          key: ValueKey<dynamic>(model.id),
          onSelectChanged: (value) {
            if (value != null) {
              setRowSelection(ValueKey<dynamic>(model.id), value);
            }
          },
          cells: decorateModel(model,
              columns: columns, actionButtons: actionButtons),
        ));
      }
      return AsyncRowsResponse(totalRows, rows);
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedMap.keys.length;
}

class SyncDataTableSource<T extends Model> extends DataTableSource
    with TableDecorator<T> {
  late List<T> sortedData = [];
  final List<TableColumn> columns;
  TableColumn? sortColumn;
  bool isAscending;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;
  bool isShowActions = false;
  List<T> get selected => selectedMap.values.toList();
  List<Widget> Function(T model, int? index)? actionButtons;

  SyncDataTableSource(
      {required this.columns,
      this.isAscending = true,
      this.sortColumn,
      this.actionButtons,
      this.paginatorController});

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

  void setData(List<T> rawData) {
    if (paginatorController?.isAttached ?? false) {
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
      if (cellA is TimeOfDay) {
        cellA = cellA.toString();
        cellB = cellB.toString();
      }
      return cellA.compareTo(cellB) * (isAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

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
      cells: decorateModel(model,
          index: index, columns: columns, actionButtons: actionButtons),
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
  bool canFilter;

  TableColumn(
      {this.initX = 0,
      this.width = 175,
      this.excelWidth,
      this.path,
      required this.attributeKey,
      this.type = 'string',
      this.canSort = true,
      this.canFilter = true,
      required this.sortKey,
      required this.key,
      required this.name});

  bool isNumeric() {
    return ['float', 'decimal', 'int', 'money', 'percentage'].contains(type);
  }
}

mixin TableDecorator<T extends Model> on DataTableSource {
  Widget _decorateCell(String val, String columnType) {
    switch (columnType) {
      // case 'image':
      // return Image.network('assets/${val}')
      case 'link':
      case 'date':
      case 'datetime':
        return Align(
          alignment: Alignment.centerLeft,
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
        return Align(alignment: Alignment.centerLeft, child: Text(val));
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

  static String _moneyFormat(dynamic value) {
    if (value is Money) {
      return NumberFormat.currency(
              locale: "en_US", symbol: value.symbol, decimalDigits: 1)
          .format(value.value);
    }
    return NumberFormat.currency(
            locale: "en_US", symbol: "Rp", decimalDigits: 1)
        .format(value);
  }

  static String _numberFormat(number) {
    var formated = NumberFormat(",##0.##", "en_US");
    return formated.format(number);
  }

  DataCell decorateValue(jsonData, TableColumn column) {
    final cell = jsonData[column.attributeKey] ?? jsonData[column.key];
    final val = _formatData(cell);
    return DataCell(Tooltip(
      message: val,
      triggerMode: TooltipTriggerMode.longPress,
      child: _decorateCell(val, column.type),
    ));
  }

  List<DataCell> decorateModel(T model,
      {List<TableColumn> columns = const [],
      int index = 0,
      List<Widget> Function(T model, int index)? actionButtons}) {
    var jsonData = model.toMap();
    var rows = columns
        .map<DataCell>((column) => decorateValue(jsonData, column))
        .toList();
    if (actionButtons != null) {
      rows.add(DataCell(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: actionButtons(model, index),
      )));
    }
    return rows;
  }
}
