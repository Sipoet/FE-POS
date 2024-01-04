import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';

class Datatable extends DataTableSource {
  late List<Model> sortedData;
  late List<String> keys;
  Function? actionButtons;

  DataCell decorateValue(cell) {
    if (cell == null) {
      return const DataCell(Text('-'));
    } else if (cell is DateTime) {
      String val = _formatDate(cell);
      return DataCell(SelectableText(val));
    } else if (cell is double || cell is int) {
      String val = _formatNumber(cell);
      return DataCell(
          Align(alignment: Alignment.centerRight, child: SelectableText(val)));
    } else {
      return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _formatDate(DateTime cell) {
    var formated = DateFormat('dd/MM/y HH:mm');
    return formated.format(cell.toUtc());
  }

  static String _formatNumber(number) {
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
      final Comparable<Object> cellA = a.toMap()[sortColumn] ?? '';
      final Comparable<Object> cellB = b.toMap()[sortColumn] ?? '';
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
