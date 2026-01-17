import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
export 'package:fe_pos/tool/query_data.dart';

typedef FilterProcess = void Function(List<FilterData>);

class TableFilterForm extends StatefulWidget {
  final List<TableColumn> columns;
  final Map<String, List<dynamic>> enums;
  final TableFilterFormController? controller;
  final FilterProcess onSubmit;
  final FilterProcess? onDownload;
  final bool showCanopy;
  const TableFilterForm({
    super.key,
    this.enums = const {},
    required this.onSubmit,
    this.onDownload,
    required this.columns,
    this.showCanopy = true,
    this.controller,
  });

  @override
  State<TableFilterForm> createState() => _TableFilterFormState();
}

class _TableFilterFormState extends State<TableFilterForm> {
  final _key = GlobalKey<FormState>();
  final _labelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  late final TableFilterFormController controller;
  late ColorScheme colorScheme;
  bool isShowFilter = false;

  final Map _textController = {};
  final Map<String, QueryOperator?> _numComparison = {};
  Map<String, dynamic> val = {};

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
        Text("Filter", style: _labelStyle),
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
                    isShowFilter ? Icons.expand_more : Icons.expand_less,
                  ),
                  label: const Divider(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
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
                Wrap(
                  runSpacing: 10.0,
                  spacing: 10.0,
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
                        child: const Text('Cari'),
                      ),
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
                          child: const Text('Download'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          controller.removeAllFilter();
                          for (final controller in _textController.values) {
                            controller.clear();
                          }
                          setState(() {
                            for (final key in val.keys) {
                              val[key] = null;
                            }
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ),
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
    return column.type.renderFilter(
      key: ValueKey('filter-${column.name}-field'),
      name: column.name,
      label: Text(column.humanizeName, style: _labelStyle),
      initialValue: controller.filterOfColumn(column.name),
      onChanged: (FilterData? filterData) {
        setState(() {
          if (filterData == null) {
            controller.removeFilter(column.name);
          } else {
            controller.setFilter(filterData);
          }
        });
      },
    );
  }

  Widget boolFilter(TableColumn column) {
    return SizedBox(
      width: 300,
      child: CheckboxListTile(
        title: Text(column.humanizeName),
        controlAffinity: ListTileControlAffinity.leading,
        value: val[column.name] as bool?,
        tristate: true,
        onChanged: (value) {
          setState(() {
            val[column.name] = value;
          });
          if (value == null) {
            controller.removeFilter(column.name);
          } else {
            controller.setFilter(
              ComparisonFilterData(key: column.name, value: value.toString()),
            );
          }
        },
      ),
    );
  }

  Widget dateFilter(TableColumn column, RangeType rangeType) {
    _textController[column.name] ??= DateRangeEditingController(null);
    return SizedBox(
      width: 300,
      height: 50,
      child: DateRangeFormField(
        rangeType: rangeType,
        controller: _textController[column.name],
        label: Text(column.humanizeName, style: _labelStyle),
        helpText: column.name,
        key: ValueKey(column.name),
        allowClear: true,
        onChanged: (value) {
          if (value == null) {
            controller.removeFilter(column.name);
          } else {
            controller.setFilter(
              BetweenFilterData(
                key: column.name,
                values: [value.start, value.end],
              ),
            );
          }
        },
      ),
    );
  }

  Widget enumFilter(TableColumn column) {
    final enumList = widget.enums[column.name];
    _textController[column.name] ??= TextEditingController();
    return DropdownMenu<String>(
      width: 300,
      controller: _textController[column.name],
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.all(12),
        border: OutlineInputBorder(),
      ),
      key: ValueKey(column.name),
      label: Text(column.humanizeName, style: _labelStyle),
      onSelected: (String? value) {
        if (value == null || value.isEmpty) {
          controller.removeFilter(column.name);
          return;
        }
        controller.setFilter(
          ComparisonFilterData(key: column.name, value: value),
        );
      },
      dropdownMenuEntries:
          const [DropdownMenuEntry<String>(value: '', label: '')] +
          enumList!
              .map<DropdownMenuEntry<String>>(
                (data) => DropdownMenuEntry(
                  value: data.toString(),
                  label: data.humanize(),
                ),
              )
              .toList(),
    );
  }

  Widget textFilter(TableColumn column) {
    _textController[column.name] ??= TextEditingController();
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
          controller.setFilter(
            ComparisonFilterData(
              key: column.name,
              operator: QueryOperator.contains,
              value: newValue,
            ),
          );
        },
        onChanged: (newValue) {
          if (newValue.isEmpty) {
            controller.removeFilter(column.name);
            return;
          }
          controller.setFilter(
            ComparisonFilterData(
              key: column.name,
              operator: QueryOperator.contains,
              value: newValue,
            ),
          );
        },
        controller: _textController[column.name],
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          label: Text(column.humanizeName, style: _labelStyle),
          border: const OutlineInputBorder(),
        ),
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
        textOnSelected: (value) => value.modelValue,
        label: Text(column.humanizeName, style: _labelStyle),
        request:
            ({
              int page = 1,
              int limit = 20,
              String searchText = '',
              CancelToken? cancelToken,
            }) {
              final server = context.read<Server>();
              return server.get(
                column.inputOptions['path'] ?? '',
                queryParam: {
                  'search_text': searchText,
                  'fields[$modelName]': attributeKey,
                  'page[page]': page.toString(),
                  'page[limit]': limit.toString(),
                },
                cancelToken: cancelToken,
              );
            },
        selecteds: val[column.name] as List<HashModel>? ?? <HashModel>[],
        attributeKey: attributeKey,
        onChanged: (value) {
          setState(() {
            val[column.name] = value;
          });
        },
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            controller.setFilter(
              ComparisonFilterData(key: column.name, value: value),
            );
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
      if (comparison == QueryOperator.between &&
          value1.isNotEmpty &&
          value2.isNotEmpty) {
        controller.setFilter(
          BetweenFilterData(key: column.name, values: [value1, value2]),
        );
      } else if (comparison != QueryOperator.between && value1.isNotEmpty) {
        controller.setFilter(
          ComparisonFilterData(
            key: column.name,
            operator: comparison,
            value: value1,
          ),
        );
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
          DropdownMenu<QueryOperator>(
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
            child: TextFormField(
              key: ValueKey('${column.name}-value1'),
              keyboardType: TextInputType.number,
              onSaved: (value) {
                comparisonChanged(column);
              },
              controller: _textController['${column.name}-val1'],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Visibility(
            visible: _numComparison[column.name] == QueryOperator.between,
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
                  border: OutlineInputBorder(),
                ),
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
          ),
        ],
      ),
    );
  }
}

class TableFilterFormController extends ChangeNotifier {
  final Map<String, FilterData> _filter = {};

  void setFilter(FilterData filterData) {
    _filter[filterData.key] = filterData;
    notifyListeners();
  }

  void removeFilter(String key) {
    _filter.remove(key);
    notifyListeners();
  }

  FilterData? filterOfColumn(String key) {
    return _filter[key];
  }

  void removeAllFilter() {
    _filter.clear();
    notifyListeners();
  }

  List<FilterData> get decoratedFilter => _filter.values.toList();
}

extension FilterText on TextEditingController {
  void clear() {
    text = '';
  }
}
