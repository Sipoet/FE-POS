import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';

extension ComparingTimeOfDay on TimeOfDay {
  int compareTo(TimeOfDay val2) {
    return toString().compareTo(val2.toString());
  }
}

enum TableColumnType {
  number,
  percentage,
  money,
  enums,
  boolean,
  date,
  datetime,
  text;
}

class TableColumn {
  double initX;
  double clientWidth;
  double? excelWidth;
  String name;
  String type;
  String humanizeName;
  String? path;
  String attributeKey;
  bool canSort;
  bool canFilter;
  Map<String, dynamic> options = {};

  TableColumn(
      {this.initX = 0,
      required this.clientWidth,
      this.excelWidth,
      this.path,
      this.options = const {},
      required this.attributeKey,
      this.type = 'string',
      this.canSort = true,
      this.canFilter = true,
      required this.name,
      required this.humanizeName});

  bool isNumeric() {
    return ['float', 'decimal', 'int', 'money', 'percentage'].contains(type);
  }
}

mixin TableDecorator<T extends Model> implements TextFormatter {
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
        return dateFormat(cell);
      case const (DateTime):
        return dateTimeLocalFormat(cell);
      case const (TimeDay):
        return timeFormat(cell);
      case const (Money):
        return moneyFormat(cell);
      case const (double):
      case const (int):
        return numberFormat(cell);
      case const (Percentage):
        return cell.format();
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

  DataCell decorateValue(jsonData, TableColumn column) {
    final cell = jsonData[column.attributeKey] ?? jsonData[column.name];
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
