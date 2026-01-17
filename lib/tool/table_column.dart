import 'package:trina_grid/trina_grid.dart';
import 'package:fe_pos/model/all_model.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';

import 'package:fe_pos/widget/number_form_field.dart';

import 'package:fe_pos/widget/time_form_field.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';

const modelKey = 'model';
const formatNumber = '#,###.#';
const locale = 'id_ID';
mixin ColumnTypeFinder {
  final route = ModelRoute();
  TableColumnType convertToColumnType(String type, Map options) {
    switch (type.toLowerCase()) {
      case 'text':
      case 'string':
        return TextTableColumnType();
      case 'number':
      case 'decimal':
      case 'float':
      case 'integer':
        return NumberTableColumnType();
      case 'percentage':
        return PercentageTableColumnType();
      case 'boolean':
      case 'bool':
        return BooleanTableColumnType();
      case 'date':
        return DateTableColumnType();
      case 'datetime':
        return DateTimeTableColumnType();
      case 'time':
        return TimeTableColumnType();
      case 'money':
        return MoneyTableColumnType();
      case 'link':
      case 'model':
        return ModelTableColumnType(
          modelClass: route.modelClassOf(options['class_name']),
        );
      case 'enum':
        return EnumTableColumnType(
          availableValues:
              options['input_options']?['enum_list']
                  ?.map<String>((e) => e.toString())
                  .toList() ??
              <String>[],
        );
      default:
        return TextTableColumnType();
    }
  }
}

class TableColumn<T extends Model> {
  double initX;
  double clientWidth;
  double? excelWidth;
  String name;
  TableColumnType type;
  Widget Function(TrinaColumnRendererContext rendererContext)? renderBody;
  dynamic Function(Model model)? getValue;
  String humanizeName;
  bool canSort;
  bool canFilter;
  TrinaColumnFrozen frozen;
  Map<String, dynamic> inputOptions = {};

  TableColumn({
    this.initX = 0,
    required this.clientWidth,
    this.excelWidth,
    this.renderBody,
    this.getValue,
    this.frozen = TrinaColumnFrozen.none,
    Map<String, dynamic>? inputOptions,
    TableColumnType? type,
    this.canSort = true,
    bool? canFilter,
    required this.name,
    required this.humanizeName,
  }) : inputOptions = inputOptions ?? const {},
       canFilter = canFilter ?? type is! ActionTableColumnType,
       type = type ?? TextTableColumnType();

  bool isNumeric() {
    return type is NumberTableColumnType ||
        type is MoneyTableColumnType ||
        type is PercentageTableColumnType;
  }
}

abstract class TableColumnType<T> {
  Widget renderFilter({
    Widget? label,
    Key? key,
    required String name,
    required void Function(FilterData? filterData) onChanged,
    FilterData? initialValue,
  });
  Widget renderCell({
    required T value,
    required TableColumn column,
    TabManager? tabManager,
  });
  T? convert(dynamic value);

  TrinaColumnType get trinaColumnType;
}

class TextTableColumnType extends TableColumnType<String> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    TextEditingController? controller,
    required void Function(FilterData? value) onChanged,
    FilterData? initialValue,
  }) {
    return SizedBox(
      width: 300,
      height: 50,
      child: TextFormField(
        key: key,
        controller: controller,
        initialValue: initialValue?.decoratedValue,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(),
          label: label,
        ),
        onChanged: (text) => text.isEmpty
            ? onChanged(null)
            : onChanged(
                ComparisonFilterData(
                  key: name,
                  operator: .contains,
                  value: text,
                ),
              ),
      ),
    );
  }

  @override
  Widget renderCell({
    required String value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value);
  }

  @override
  String convert(dynamic value) => value.toString();

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.text();
}

class ActionTableColumnType<T extends Model> extends TableColumnType<T> {
  Widget Function(T model) action;
  ActionTableColumnType({required this.action});
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required void Function(FilterData value) onChanged,
    FilterData? initialValue,
  }) {
    return SizedBox(key: key);
  }

  @override
  Widget renderCell({
    required T value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return action(value);
  }

  @override
  T convert(dynamic value) => value as T;

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.text();
}

class DateTableColumnType extends TableColumnType<Date> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required void Function(FilterData? value) onChanged,
    FilterData? initialValue,
  }) {
    DateTimeRange<Date>? initialDateTime;
    if (initialValue is BetweenFilterData) {
      initialDateTime = DateTimeRange<Date>(
        start: initialValue.values.first,
        end: initialValue.values.last,
      );
    }
    return SizedBox(
      width: 300,
      height: 50,
      child: DateRangeFormField(
        key: key,
        rangeType: DateRangeType(),
        initialDateRange: initialDateTime,
        label: label,
        allowClear: true,
        onChanged: (dateRange) => dateRange == null
            ? onChanged(null)
            : onChanged(
                BetweenFilterData(
                  key: name,
                  values: [dateRange.start, dateRange.end],
                ),
              ),
      ),
    );
  }

  @override
  Widget renderCell({
    required Date? value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value?.format() ?? '');
  }

  @override
  Date? convert(dynamic value) =>
      value is Date ? value : Date.tryParse(value.toString());

  @override
  TrinaColumnType get trinaColumnType =>
      TrinaColumnType.date(format: 'dd/MM/yyyy');
}

class DateTimeTableColumnType extends TableColumnType<DateTime> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    DateRangeEditingController? controller,
    required void Function(FilterData? value) onChanged,
    FilterData? initialValue,
  }) {
    DateTimeRange? initialDateTime;
    if (initialValue is BetweenFilterData) {
      initialDateTime = DateTimeRange(
        start: initialValue.values.first,
        end: initialValue.values.last,
      );
    }
    return SizedBox(
      width: 300,
      height: 50,
      child: DateRangeFormField(
        key: key,
        controller: controller,
        rangeType: DateTimeRangeType(),
        initialDateRange: initialDateTime,
        label: label,
        allowClear: true,
        onChanged: (dateRange) => dateRange == null
            ? onChanged(null)
            : onChanged(
                BetweenFilterData(
                  key: name,
                  values: [dateRange.start, dateRange.end],
                ),
              ),
      ),
    );
  }

  @override
  Widget renderCell({
    required DateTime? value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value?.toLocal().format() ?? '');
  }

  @override
  DateTime convert(dynamic value) =>
      value is DateTime ? value : DateTime.parse(value.toString());

  @override
  TrinaColumnType get trinaColumnType =>
      TrinaColumnType.dateTime(format: 'dd/MM/yyyy HH:mm');
}

class TimeTableColumnType extends TableColumnType<TimeOfDay> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    TimeOfDay? start;
    TimeOfDay? end;
    if (initialValue is BetweenFilterData) {
      start = initialValue.values.first;
      end = initialValue.values.last;
    }
    return Column(
      children: [
        if (label != null) label,
        Row(
          children: [
            SizedBox(
              width: 150,
              height: 50,
              child: TimeFormField(
                key: key,
                initialValue: start,
                label: Text('Dari'),
                onChanged: (time) {
                  start = time;
                  if (start != null && end != null) {
                    onChanged(
                      BetweenFilterData(key: name, values: [start, end]),
                    );
                  } else {
                    onChanged(null);
                  }
                },
              ),
            ),
            SizedBox(
              width: 150,
              height: 50,
              child: TimeFormField(
                key: key,
                initialValue: end,
                label: Text('Sampai'),
                onChanged: (time) {
                  end = time;
                  if (start != null && end != null) {
                    onChanged(
                      BetweenFilterData(key: name, values: [start, end]),
                    );
                  } else {
                    onChanged(null);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget renderCell({
    TimeOfDay? value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value?.format24Hour() ?? '');
  }

  @override
  TimeOfDay? convert(dynamic value) {
    if (value is String) {
      final datetime = DateTime.tryParse(value);
      if (datetime == null) {
        return null;
      }
      return TimeOfDay.fromDateTime(datetime.toLocal());
    } else if (value is DateTime) {
      return TimeOfDay.fromDateTime(value.toLocal());
    } else if (value is TimeOfDay) {
      return value;
    }
    return null;
  }

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.time();
}

typedef ChangeFunc = void Function(FilterData? value);

class NumberTableColumnType extends TableColumnType<double> with TextFormatter {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    TextEditingController? operatorController,
    TextEditingController? startValController,
    TextEditingController? endValController,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    return NumberFilterField(
      label: label,
      onChanged: onChanged,
      name: name,
      key: key,
      initialValue: initialValue,
    );
  }

  @override
  Widget renderCell({
    required double value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(numberFormat(value));
  }

  @override
  double convert(dynamic value) => double.parse(value.toString());

  @override
  TrinaColumnType get trinaColumnType =>
      TrinaColumnType.number(locale: locale, format: formatNumber);
}

class NumberFilterField extends StatefulWidget {
  final Widget? label;
  final String name;
  final ChangeFunc onChanged;
  final FilterData? initialValue;
  const NumberFilterField({
    super.key,
    required this.onChanged,
    this.label,
    this.initialValue,
    required this.name,
  });

  @override
  State<NumberFilterField> createState() => _NumberFilterFieldState();
}

class _NumberFilterFieldState extends State<NumberFilterField> {
  QueryOperator? operatorFilter;

  double? start;
  double? end;
  final operatorController = TextEditingController(text: '');
  final startValController = TextEditingController(text: '');
  final endValController = TextEditingController(text: '');
  @override
  void initState() {
    final filterData = widget.initialValue;
    if (filterData == null) {
    } else if (filterData is BetweenFilterData) {
      start = filterData.values.first;
      startValController.text = start.toString();
      end = filterData.values.last;
      endValController.text = end.toString();
      operatorFilter = .between;
    } else if (filterData is ComparisonFilterData) {
      start = filterData.value;
      operatorFilter = filterData.operator;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu<QueryOperator>(
            key: ValueKey('${widget.name}-operator'),
            width: 170,
            initialSelection: operatorFilter,
            onSelected: (value) {
              setState(() {
                operatorFilter = value;
              });
              checkChanged();
            },
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            requestFocusOnTap: false,
            controller: operatorController,
            label: widget.label,
            dropdownMenuEntries: QueryOperator.values
                .map<DropdownMenuEntry<QueryOperator>>(
                  (data) => DropdownMenuEntry<QueryOperator>(
                    value: data,
                    label: data.humanize(),
                  ),
                )
                .toList(),
          ),
          SizedBox(
            width: 130,
            child: NumberFormField<double>(
              key: ValueKey('${widget.name}-value1'),
              controller: startValController,
              label: Text(
                operatorFilter == QueryOperator.between ? 'Mulai' : 'Nilai',
              ),
              onChanged: (val) {
                start = val;
                checkChanged();
              },
            ),
          ),
          Visibility(
            visible: operatorFilter == QueryOperator.between,
            child: SizedBox(
              width: 130,
              child: NumberFormField<double>(
                key: ValueKey('${widget.name}-value2'),
                controller: endValController,
                label: Text('Sampai'),
                onChanged: (val) {
                  end = val;
                  checkChanged();
                },
              ),
            ),
          ),
          IconButton.filled(
            onPressed: () {
              startValController.clear();
              endValController.clear();
              operatorController.clear();
              widget.onChanged(null);
            },
            icon: const Icon(Icons.close),
            // color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void checkChanged() {
    if (start != null &&
        end != null &&
        operatorFilter == QueryOperator.between) {
      widget.onChanged(
        BetweenFilterData(key: widget.name, values: [start, end]),
      );
    } else if (start != null &&
        operatorFilter != null &&
        operatorFilter != QueryOperator.between) {
      widget.onChanged(
        ComparisonFilterData(
          key: widget.name,
          operator: operatorFilter!,
          value: start,
        ),
      );
    } else {
      widget.onChanged(null);
    }
  }
}

class MoneyTableColumnType extends TableColumnType<Money> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    TextEditingController? operatorController,
    TextEditingController? startValController,
    TextEditingController? endValController,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    return NumberFilterField(
      label: label,
      onChanged: onChanged,
      name: name,
      key: key,
      initialValue: initialValue,
    );
  }

  @override
  Widget renderCell({
    required Money value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value.format());
  }

  @override
  Money convert(dynamic value) => Money.parse(value);

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.currency(
    locale: locale,
    // format: _formatNumber,
    symbol: 'Rp',
    decimalDigits: 2,
  );
}

class ModelTableColumnType<T extends Model> extends TableColumnType<T>
    with PlatformChecker {
  ModelClass<T> modelClass;
  final route = ModelRoute();
  ModelTableColumnType({required this.modelClass});
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    return Container(
      width: 300,
      constraints: const BoxConstraints(minHeight: 50),
      child: AsyncDropdownMultiple<T>(
        key: key,
        modelClass: modelClass,
        textOnSearch: (model) => [
          model.modelValue,
          if (model.valueDescription != null) model.valueDescription,
        ].join(' - '),
        textOnSelected: (model) => model.modelValue,
        label: label,
        onChanged: (values) => values.isEmpty
            ? onChanged(null)
            : onChanged(ComparisonFilterData(key: name, value: values)),
      ),
    );
  }

  @override
  Widget renderCell({
    required T value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return InkWell(
      onTap: () => _openModelDetailPage(
        tableColumn: column,
        value: value,
        tabManager: tabManager,
      ),
      child: Text(value.modelValue, textAlign: TextAlign.left),
    );
  }

  void _openModelDetailPage({
    required TableColumn tableColumn,
    required T value,
    TabManager? tabManager,
  }) {
    if (tabManager == null) {
      return;
    }
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
        "${tableColumn.humanizeName} ${value.id}",
        route.detailPageOf(value),
      );
    } else {
      tabManager.addTab(
        "${tableColumn.humanizeName} ${value.id}",
        route.detailPageOf(value),
      );
    }
  }

  @override
  T convert(dynamic value) => value is T ? value : modelClass.fromJson(value);

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.text();
}

class PercentageTableColumnType extends TableColumnType<Percentage>
    with TextFormatter {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    return NumberFilterField(
      label: label,
      onChanged: onChanged,
      name: name,
      key: key,
      initialValue: initialValue,
    );
    // QueryOperator? operatorFilter;
    // return SizedBox(
    //   width: 300,
    //   height: 50,
    //   child: Row(
    //     children: [
    //       DropdownMenu<QueryOperator>(
    //         width: 170,
    //         initialSelection: operatorFilter,
    //         onSelected: (value) {
    //           // setState(() {
    //           if (value != null) {
    //             operatorFilter = value;
    //           }
    //           // });
    //         },
    //         inputDecorationTheme: const InputDecorationTheme(
    //           border: OutlineInputBorder(),
    //           contentPadding: EdgeInsets.all(12),
    //         ),
    //         requestFocusOnTap: false,
    //         controller: operatorController,
    //         label: label,
    //         dropdownMenuEntries: QueryOperator.values
    //             .map<DropdownMenuEntry<QueryOperator>>(
    //               (data) => DropdownMenuEntry<QueryOperator>(
    //                 value: data,
    //                 label: data.humanize(),
    //               ),
    //             )
    //             .toList(),
    //       ),
    //       SizedBox(
    //         width: 130,
    //         child: PercentageFormField(
    //           key: key,
    //           controller: startValController,
    //           initialValue: selected,
    //           label: Text(
    //             operatorFilter == QueryOperator.between ? 'Mulai' : 'Nilai',
    //           ),
    //           onChanged: onChanged,
    //         ),
    //       ),
    //       Visibility(
    //         visible: operatorFilter == QueryOperator.between,
    //         child: SizedBox(
    //           width: 130,
    //           child: PercentageFormField(
    //             key: key,
    //             controller: endValController,
    //             initialValue: selected,
    //             label: Text('Sampai'),
    //             onChanged: onChanged,
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  @override
  Widget renderCell({
    Percentage? value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value?.format() ?? '');
  }

  @override
  Percentage? convert(dynamic value) =>
      value is Percentage ? value : Percentage.tryParse(value.toString());

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.text();
}

class BooleanTableColumnType extends TableColumnType<bool> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    bool? selected;
    if (initialValue != null && initialValue is ComparisonFilterData) {
      selected = initialValue.value;
    }
    return SizedBox(
      width: 300,
      child: CheckboxListTile(
        value: selected,
        controlAffinity: ListTileControlAffinity.leading,
        title: label,
        tristate: true,
        onChanged: (val) => val == null
            ? onChanged(null)
            : onChanged(ComparisonFilterData(key: name, value: val)),
      ),
    );
  }

  @override
  Widget renderCell({
    required bool value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value.toString());
  }

  @override
  bool convert(dynamic value) => value == true;

  @override
  TrinaColumnType get trinaColumnType => TrinaColumnType.select([true, false]);
}

class EnumTableColumnType extends TableColumnType<String> with TextFormatter {
  List<String> availableValues;
  EnumTableColumnType({required this.availableValues});
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    TextEditingController? controller,
    required ChangeFunc onChanged,
    FilterData? initialValue,
  }) {
    String? selected;
    if (initialValue != null && initialValue is ComparisonFilterData) {
      selected = initialValue.value.toString();
    }
    return DropdownMenu<String?>(
      width: 300,
      key: key,
      controller: controller,
      initialSelection: selected,
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.all(12),
        border: OutlineInputBorder(),
      ),
      label: label,
      onSelected: (val) => val == null
          ? onChanged(null)
          : onChanged(ComparisonFilterData(key: name, value: val)),
      dropdownMenuEntries: [
        DropdownMenuEntry<String?>(value: null, label: ''),
        ...availableValues.map<DropdownMenuEntry<String>>(
          (data) => DropdownMenuEntry(value: data, label: data.toTitleCase()),
        ),
      ],
    );
  }

  @override
  Widget renderCell({
    required String value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value.toTitleCase());
  }

  @override
  String convert(dynamic value) => value.toString();

  @override
  TrinaColumnType get trinaColumnType =>
      TrinaColumnType.select(availableValues);
}
