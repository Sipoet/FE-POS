import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/table_column.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';

class ModelCard<T extends Model> extends StatelessWidget with TextFormatter {
  final T model;
  final bool expanded;
  final List<TableColumn> columns;
  final Widget? action;
  final TabManager? tabManager;
  const ModelCard({
    required this.model,
    this.action,
    this.expanded = false,
    this.tabManager,
    this.columns = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final modelHash = model.asMap();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: .max,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    titleOfModel(model),
                    style: TextFormatter.labelStyle,
                    overflow: .ellipsis,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const Divider(),
            ...columns.map(
              (column) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Align(
                  alignment: .topLeft,
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 10,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        "${column.humanizeName}:",
                        style: TextFormatter.labelStyle,
                      ),
                      cell(column, modelHash[column.name]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cell(TableColumn column, Object? value) {
    if (value == null) {
      return SizedBox();
    }
    return column.type.renderCell(
      value: value,
      column: column,
      tabManager: tabManager,
    );
  }

  String titleOfModel(T model) {
    List<String> arr = [model.modelValue];
    if (model.valueDescription != null) {
      arr.add(model.valueDescription!);
    }
    return arr.join(' - ');
  }
}
