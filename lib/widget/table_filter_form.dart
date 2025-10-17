import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableFilterForm extends StatefulWidget {
  final List<TableColumn> columns;
  final Map<String, List<dynamic>> enums;
  final TableFilterFormController? controller;
  final void Function(Map) onSubmit;
  final void Function(Map)? onDownload;
  final bool showCanopy;
  const TableFilterForm(
      {super.key,
      this.enums = const {},
      required this.onSubmit,
      this.onDownload,
      required this.columns,
      this.showCanopy = true,
      this.controller});

  @override
  State<TableFilterForm> createState() => _TableFilterFormState();
}

class _TableFilterFormState extends State<TableFilterForm> {
  final _key = GlobalKey<FormState>();
  final _labelStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  late final TableFilterFormController controller;
  late ColorScheme colorScheme;
  bool isShowFilter = false;

  final Map _textController = {};
  final Map _numComparison = {};

  @override
  void initState() {
    isShowFilter = !widget.showCanopy;
    controller = widget.controller ?? TableFilterFormController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Filter",
          style: _labelStyle,
        ),
        Visibility(
            visible: widget.showCanopy,
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isShowFilter = !isShowFilter;
                      });
                    },
                    icon: Icon(
                        isShowFilter ? Icons.expand_more : Icons.expand_less),
                    label: const Divider(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            )),
        Visibility(
          visible: isShowFilter,
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 10.0,
                  spacing: 10.0,
                  children: widget.columns
                      .where((element) => element.canFilter)
                      .map<Widget>((column) => formFilter(column))
                      .toList(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                          onPressed: () {
                            if (_key.currentState!.validate()) {
                              _key.currentState!.save();
                              widget.onSubmit(controller.decoratedFilter);
                            }
                          },
                          child: const Text('Cari')),
                    ),
                    Visibility(
                      visible: widget.onDownload != null,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                            onPressed: () {
                              if (_key.currentState!.validate()) {
                                _key.currentState!.save();
                                widget.onDownload!(controller.decoratedFilter);
                              }
                            },
                            child: const Text('Download')),
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.all(10.0),
                    //   child: ElevatedButton(
                    //       onPressed: () {
                    //         controller.removeAllFilter();
                    //       },
                    //       child: const Text('Hapus Filter')),
                    // )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget formFilter(TableColumn column) {
    switch (column.type) {
      case TableColumnType.text:
        return textFilter(column);
      case TableColumnType.money:
      case TableColumnType.percentage:
      case TableColumnType.number:
        return numberFilter(column);
      case TableColumnType.boolean:
        return boolFilter(column);
      case TableColumnType.date:
        return dateFilter(column, datePickerOnly: true);
      case TableColumnType.datetime:
        return dateFilter(column);
      case TableColumnType.enums:
        return enumFilter(column);
      case TableColumnType.model:
        return linkFilter(column);
      default:
        return SizedBox(
          width: 300,
          height: 90,
          child: TextFormField(
            enabled: false,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12),
                label: Text(
                  column.name,
                  style: _labelStyle,
                ),
                border: const OutlineInputBorder(),
                helperStyle: const TextStyle(fontSize: 11),
                helperText: 'Tidak support filter'),
          ),
        );
    }
  }

  String decorateTimeRange(DateTimeRange range, TableColumnType type) {
    if (type.isDate()) {
      return [
        Date.parsingDateTime(range.start).toIso8601String(),
        Date.parsingDateTime(range.end).toIso8601String()
      ].join(',');
    } else {
      return [range.start.toIso8601String(), range.end.toIso8601String()]
          .join(',');
    }
  }

  Map<String, bool?> val = {};
  Widget boolFilter(TableColumn column) {
    return SizedBox(
      width: 300,
      child: CheckboxListTile(
          title: Text(column.humanizeName),
          controlAffinity: ListTileControlAffinity.leading,
          value: val[column.name],
          tristate: true,
          onChanged: (value) {
            setState(() {
              val[column.name] = value;
            });
            if (value == null) {
              controller.removeFilter(column.name);
            } else {
              controller.setFilter(column.name, 'eq', value.toString());
            }
          }),
    );
  }

  Widget dateFilter(TableColumn column, {bool datePickerOnly = false}) {
    return SizedBox(
      width: 300,
      height: 50,
      child: DateRangeFormField(
        rangeType: datePickerOnly ? DateRangeType() : DateTimeRangeType(),
        label: Text(column.humanizeName, style: _labelStyle),
        helpText: column.name,
        key: ValueKey(column.name),
        allowClear: true,
        onChanged: (value) {
          if (value == null) {
            controller.removeFilter(column.name);
          } else {
            controller.setFilter(
                column.name, 'btw', decorateTimeRange(value, column.type));
          }
        },
      ),
    );
  }

  Widget enumFilter(TableColumn column) {
    final enumList = widget.enums[column.name];
    return DropdownMenu<String>(
        width: 300,
        inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.all(12), border: OutlineInputBorder()),
        key: ValueKey(column.name),
        label: Text(
          column.humanizeName,
          style: _labelStyle,
        ),
        onSelected: (String? value) {
          if (value == null || value.isEmpty) {
            controller.removeFilter(column.name);
            return;
          }
          controller.setFilter(column.name, 'eq', value);
        },
        dropdownMenuEntries: const [
              DropdownMenuEntry<String>(value: '', label: '')
            ] +
            enumList!
                .map<DropdownMenuEntry<String>>((data) => DropdownMenuEntry(
                    value: data.toString(), label: data.humanize()))
                .toList());
  }

  Widget textFilter(TableColumn column) {
    return SizedBox(
      width: 300,
      height: 50,
      child: TextFormField(
        key: ValueKey(column.name),
        onSaved: (newValue) {
          if (newValue == null || newValue.isEmpty) {
            controller.removeFilter(column.name);
            return;
          }
          controller.setFilter(column.name, 'like', newValue);
        },
        onChanged: (newValue) {
          if (newValue.isEmpty) {
            controller.removeFilter(column.name);
            return;
          }
          controller.setFilter(column.name, 'like', newValue);
        },
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            label: Text(column.humanizeName, style: _labelStyle),
            border: const OutlineInputBorder()),
      ),
    );
  }

  Widget linkFilter(TableColumn column) {
    final modelName = column.inputOptions['model_name'] ?? '';
    final attributeKey = column.inputOptions['attribute_key'] ?? 'id';
    return Container(
      width: 300,
      constraints: const BoxConstraints(minHeight: 50),
      child: AsyncDropdownMultiple<HashModel>(
        modelClass: HashModelClass(),
        textOnSearch: (value) =>
            "${value['id'].toString()} - ${value['attributes'][attributeKey]}",
        textOnSelected: (value) => value.modelValue.toString(),
        label: Text(column.humanizeName, style: _labelStyle),
        request: (
            {int page = 1,
            int limit = 20,
            String searchText = '',
            CancelToken? cancelToken}) {
          final server = context.read<Server>();
          return server.get(column.inputOptions['path'] ?? '',
              queryParam: {
                'search_text': searchText,
                'fields[$modelName]': attributeKey,
                'page[page]': page.toString(),
                'page[limit]': limit.toString(),
              },
              cancelToken: cancelToken);
        },
        attributeKey: attributeKey,
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            final decoratedValue =
                value.map<String>((e) => e.id.toString()).join(',');
            controller.setFilter(column.name, 'eq', decoratedValue);
          } else {
            controller.removeFilter(column.name);
          }
        },
      ),
    );
  }

  void comparisonChanged(column) {
    setState(() {
      final comparison = _numComparison[column.name];
      final value1 = _textController['${column.name}-val1'].text;
      final value2 = _textController['${column.name}-val2'].text;
      if (comparison == null) {
        controller.removeFilter(column.name);
        return;
      }
      if (comparison == 'btw' && value1.isNotEmpty && value2.isNotEmpty) {
        controller.setFilter(column.name, comparison, '$value1,$value2');
      } else if (comparison != 'btw' && value1.isNotEmpty) {
        controller.setFilter(column.name, comparison, value1);
      }
    });
  }

  Widget numberFilter(TableColumn column) {
    _textController['${column.name}-val1'] ??= TextEditingController();
    _textController['${column.name}-val2'] ??= TextEditingController();
    _textController['${column.name}-cmpr'] ??= TextEditingController();

    return SizedBox(
      height: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownMenu<String>(
              width: 170,
              onSelected: (value) {
                setState(() {
                  _numComparison[column.name] = value;
                });
              },
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              requestFocusOnTap: false,
              controller: _textController['${column.name}-cmpr'],
              label: Text(column.humanizeName, style: _labelStyle),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'eq', label: '='),
                DropdownMenuEntry(value: 'not', label: 'bukan'),
                DropdownMenuEntry(value: 'gt', label: '>'),
                DropdownMenuEntry(value: 'gte', label: '>='),
                DropdownMenuEntry(value: 'lt', label: '<'),
                DropdownMenuEntry(value: 'lte', label: '<='),
                DropdownMenuEntry(value: 'btw', label: 'antara'),
                DropdownMenuEntry(value: '', label: ''),
              ]),
          SizedBox(
            width: 130,
            child: TextFormField(
              key: ValueKey('${column.name}-value1'),
              keyboardType: TextInputType.number,
              onSaved: (value) {
                comparisonChanged(column);
              },
              controller: _textController['${column.name}-val1'],
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder()),
            ),
          ),
          Visibility(
            visible: _numComparison[column.name] == 'btw',
            child: SizedBox(
              width: 130,
              child: TextFormField(
                key: ValueKey('${column.name}-value2'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  comparisonChanged(column);
                },
                controller: _textController['${column.name}-val2'],
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder()),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: () {
              _textController['${column.name}-val1'].text = '';
              _textController['${column.name}-val2'].text = '';
              _textController['${column.name}-cmpr'].text = '';
              controller.removeFilter(column.name);
            },
            icon: const Icon(Icons.close),
            // color: colorScheme.primary,
          )
        ],
      ),
    );
  }
}

class TableFilterFormController extends ChangeNotifier {
  Map<String, Map<String, dynamic>> _filter = {};

  void setFilter(String key, String comparison, dynamic value) {
    if (_filter[key] == null) {
      _filter[key] = {};
    }
    _filter[key]![comparison] = value;
    notifyListeners();
  }

  void removeFilter(String key) {
    _filter.remove(key);
    notifyListeners();
  }

  void removeAllFilter() {
    _filter = {};
    notifyListeners();
  }

  Map get decoratedFilter => _decoratedFilter();

  Map _decoratedFilter() {
    Map newFilter = {};
    _filter.forEach((key, Map values) {
      values.forEach((comparison, value) {
        newFilter['filter[$key][$comparison]'] = value;
      });
    });
    return newFilter;
  }
}
