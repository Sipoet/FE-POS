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
        return NumberTableColumnType(DoubleType());
      case 'integer':
        return NumberTableColumnType(IntegerType());
      case 'percentage':
        return PercentageTableColumnType();
      case 'boolean':
      case 'bool':
        return BooleanTableColumnType();
      case 'date':
        return DateTableColumnType(DateRangeType());
      case 'datetime':
        return DateTableColumnType(DateTimeRangeType());
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

class FilterFormController extends ChangeNotifier {
  FilterData? value;
  FilterFormController(this.value);

  void clear() {
    value = null;
    notifyListeners();
  }

  void setFilterData(FilterData? filterData, {bool notify = false}) {
    value = filterData;
    if (notify) {
      notifyListeners();
    }
  }

  String? get key => value?.key;
}

abstract class TableColumnType<T> {
  Widget renderFilter({
    Widget? label,
    Key? key,
    required String name,
    required FilterFormController controller,
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
    required FilterFormController controller,
  }) {
    final textController = TextEditingController(
      text: controller.value?.decoratedValue,
    );
    debugPrint('==render filter');
    controller.addListener(() {
      debugPrint('==value text berubah ${controller.value?.decoratedValue}');
      if (controller.value == null) {
        textController.clear();
      } else {
        textController.text = controller.value!.decoratedValue;
      }
    });
    return SizedBox(
      width: 300,
      height: 50,
      child: TextFormField(
        key: key,
        controller: textController,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(),
          label: label,
        ),
        onChanged: (text) => text.isEmpty
            ? controller.setFilterData(null)
            : controller.setFilterData(
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
    required FilterFormController controller,
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

class DateTableColumnType<T extends DateTime> extends TableColumnType<T> {
  RangeType<T> rangeType;
  DateTableColumnType(this.rangeType);
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    DateTimeRange<T>? initialDateTime;
    final value = controller.value;
    if (value is BetweenFilterData) {
      initialDateTime = DateTimeRange<T>(
        start: value.values.first,
        end: value.values.last,
      );
    }
    final dateController = DateRangeEditingController<T>(initialDateTime);
    controller.addListener(() {
      final filterData = controller.value;
      if (filterData == null) {
        dateController.clear();
      } else if (filterData is BetweenFilterData) {
        dateController.value = DateTimeRange<T>(
          start: filterData.values.first,
          end: filterData.values.last,
        );
      }
    });
    return SizedBox(
      width: 300,
      height: 50,
      child: DateRangeFormField<T>(
        key: key,
        rangeType: rangeType,
        onChanged: (dateRange) => dateRange == null
            ? controller.setFilterData(null)
            : controller.setFilterData(
                BetweenFilterData(
                  key: name,
                  values: [dateRange.start, dateRange.end],
                ),
              ),
        controller: dateController,
        label: label,
        allowClear: true,
      ),
    );
  }

  @override
  Widget renderCell({
    required T? value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(value?.format() ?? '');
  }

  @override
  T? convert(dynamic value) => rangeType.convert(value);

  @override
  TrinaColumnType get trinaColumnType => T == Date
      ? TrinaColumnType.date(format: 'dd/MM/yyyy')
      : TrinaColumnType.dateTime(format: 'dd/MM/yyyy HH:mm');
}

class TimeTableColumnType extends TableColumnType<TimeOfDay> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    TimeOfDay? start;
    TimeOfDay? end;

    final value = controller.value;
    if (value is BetweenFilterData) {
      start = value.values.first;
      end = value.values.last;
    }
    final startController = TextEditingController(text: start?.format24Hour());
    final endController = TextEditingController(text: end?.format24Hour());
    controller.addListener(() {
      final value = controller.value;
      if (value == null) {
        startController.clear();
        endController.clear();
      } else if (value is BetweenFilterData) {
        startController.text = value.values.first.format24Hour();
        endController.text = value.values.last.format24Hour();
      }
    });
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
                controller: startController,
                label: Text('Dari'),
                onChanged: (time) {
                  start = time;
                  if (start != null && end != null) {
                    controller.setFilterData(
                      BetweenFilterData(key: name, values: [start, end]),
                    );
                  } else {
                    controller.setFilterData(null);
                  }
                },
              ),
            ),
            SizedBox(
              width: 150,
              height: 50,
              child: TimeFormField(
                key: key,
                controller: endController,
                label: Text('Sampai'),
                onChanged: (time) {
                  end = time;
                  if (start != null && end != null) {
                    controller.setFilterData(
                      BetweenFilterData(key: name, values: [start, end]),
                    );
                  } else {
                    controller.setFilterData(null);
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

class NumberTableColumnType<T> extends TableColumnType<T> with TextFormatter {
  NumType<T> numType;
  NumberTableColumnType(this.numType);
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    return NumberFilterField<T>(
      label: label,
      controller: controller,
      numType: numType,
      name: name,
      key: key,
    );
  }

  @override
  Widget renderCell({
    required T value,
    required TableColumn column,
    TabManager? tabManager,
  }) {
    return Text(numberFormat(value));
  }

  @override
  T? convert(dynamic value) => numType.convert(value.toString());

  @override
  TrinaColumnType get trinaColumnType =>
      TrinaColumnType.number(locale: locale, format: formatNumber);
}

class NumberFilterField<T> extends StatefulWidget {
  final Widget? label;
  final String name;
  final FilterFormController controller;
  final NumType<T> numType;
  const NumberFilterField({
    super.key,
    required this.controller,
    required this.numType,
    this.label,
    required this.name,
  });

  @override
  State<NumberFilterField> createState() => _NumberFilterFieldState<T>();
}

class _NumberFilterFieldState<T> extends State<NumberFilterField<T>> {
  QueryOperator? operatorFilter;

  T? start;
  T? end;
  final operatorController = TextEditingController(text: '');
  final startValController = TextEditingController(text: '');
  final endValController = TextEditingController(text: '');
  FilterFormController get controller => widget.controller;
  @override
  void initState() {
    controller.addListener(changeData);
    changeData();

    super.initState();
  }

  void changeData() {
    final value = controller.value;
    if (value == null) {
      startValController.clear();
      endValController.clear();
      operatorController.clear();
    } else if (value is BetweenFilterData) {
      start = value.values.first;
      startValController.text = start.toString();
      end = value.values.last;
      endValController.text = end.toString();
      operatorFilter = .between;
    } else if (value is ComparisonFilterData) {
      start = value.value;
      operatorFilter = value.operator;
    }
  }

  @override
  void dispose() {
    controller.removeListener(changeData);
    startValController.dispose();
    endValController.dispose();
    operatorController.dispose();
    super.dispose();
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
            child: NumberFormField<T>(
              key: ValueKey('${widget.name}-value1-number'),
              controller: startValController,
              numType: widget.numType,
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
              child: NumberFormField<T>(
                key: ValueKey('${widget.name}-value2-number'),
                controller: endValController,
                numType: widget.numType,
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
              controller.setFilterData(null);
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
      controller.setFilterData(
        BetweenFilterData(key: widget.name, values: [start, end]),
      );
    } else if (start != null &&
        operatorFilter != null &&
        operatorFilter != QueryOperator.between) {
      controller.setFilterData(
        ComparisonFilterData(
          key: widget.name,
          operator: operatorFilter!,
          value: start,
        ),
      );
    } else {
      controller.setFilterData(null);
    }
  }
}

class MoneyTableColumnType extends TableColumnType<Money> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    return NumberFilterField<Money>(
      label: label,
      numType: MoneyType(),
      controller: controller,
      name: name,
      key: key,
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
    required FilterFormController controller,
  }) {
    return ModelFilterForm(
      name: name,
      controller: controller,
      key: key,
      modelClass: modelClass,
      label: label,
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

class ModelFilterForm<T extends Model> extends StatefulWidget {
  final FilterFormController controller;
  final String name;
  final Widget? label;
  final ModelClass<T> modelClass;
  const ModelFilterForm({
    super.key,
    this.label,
    required this.modelClass,
    required this.name,
    required this.controller,
  });

  @override
  State<ModelFilterForm> createState() => _ModelFilterFormState<T>();
}

class _ModelFilterFormState<T extends Model> extends State<ModelFilterForm<T>> {
  List<T> selected = [];
  FilterFormController get controller => widget.controller;
  @override
  void initState() {
    controller.addListener(changeData);
    changeData();
    super.initState();
  }

  void changeData() {
    final value = controller.value;
    if (value is ComparisonFilterData) {
      setState(() {
        selected = value.value;
      });
    } else {
      setState(() {
        selected.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      constraints: const BoxConstraints(minHeight: 50),
      child: AsyncDropdownMultiple<T>(
        selecteds: selected,
        key: ValueKey('${widget.name}-filter-model-form-1'),
        modelClass: widget.modelClass,
        textOnSearch: (model) => [
          model.modelValue,
          if (model.valueDescription != null) model.valueDescription,
        ].join(' - '),
        textOnSelected: (model) => model.modelValue,
        label: widget.label,
        onChanged: (values) {
          setState(() {
            selected = values;
          });

          values.isEmpty
              ? controller.setFilterData(null)
              : controller.setFilterData(
                  ComparisonFilterData(key: widget.name, value: values),
                );
        },
      ),
    );
  }
}

class PercentageTableColumnType extends TableColumnType<Percentage>
    with TextFormatter {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    return NumberFilterField<Percentage>(
      label: label,
      controller: controller,
      numType: PercentageType(),
      name: name,
      key: key,
    );
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
  TrinaColumnType get trinaColumnType => TrinaColumnType.percentage();
}

class BooleanTableColumnType extends TableColumnType<bool> {
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    return BoolFilterForm(
      name: name,
      controller: controller,
      label: label,
      key: key,
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

class BoolFilterForm extends StatefulWidget {
  final Widget? label;
  final String name;
  final FilterFormController controller;
  const BoolFilterForm({
    required this.name,
    super.key,
    this.label,
    required this.controller,
  });

  @override
  State<BoolFilterForm> createState() => _BoolFilterFormState();
}

class _BoolFilterFormState extends State<BoolFilterForm> {
  bool? selected;
  FilterFormController get controller => widget.controller;
  @override
  void initState() {
    controller.addListener(() {
      final value = controller.value;
      if (value == null) {
        setState(() {
          selected = null;
        });
      } else if (value is ComparisonFilterData) {
        selected = value.value;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: CheckboxListTile(
        value: selected,
        controlAffinity: ListTileControlAffinity.leading,
        title: widget.label,
        tristate: true,
        onChanged: (val) => setState(() {
          selected = val;
          val == null
              ? controller.setFilterData(null)
              : controller.setFilterData(
                  ComparisonFilterData(key: widget.name, value: val),
                );
        }),
      ),
    );
  }
}

class EnumTableColumnType extends TableColumnType<String> with TextFormatter {
  List<String> availableValues;
  EnumTableColumnType({required this.availableValues});
  @override
  Widget renderFilter({
    Widget? label,
    required String name,
    Key? key,
    required FilterFormController controller,
  }) {
    String? selected;
    final value = controller.value;
    if (value != null && value is ComparisonFilterData) {
      selected = value.value.toString();
    }
    final dropdownController = TextEditingController(text: selected);

    controller.addListener(() {
      if (controller.value == null) {
        dropdownController.clear();
      } else {
        dropdownController.text = controller.value?.decoratedValue ?? '';
      }
    });
    return DropdownMenu<String?>(
      width: 300,
      key: key,
      controller: dropdownController,
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.all(12),
        border: OutlineInputBorder(),
      ),
      label: label,
      onSelected: (val) => val == null
          ? controller.setFilterData(null)
          : controller.setFilterData(
              ComparisonFilterData(key: name, value: val),
            ),
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
