import 'package:fe_pos/tool/datatable.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:flutter/material.dart';

class TableFilterForm extends StatefulWidget {
  final List<TableColumn> columns;
  final Map<String, List<dynamic>> enums;
  final TableFilterFormController? controller;
  final void Function(Map)? onSubmit;
  const TableFilterForm(
      {super.key,
      this.enums = const {},
      this.onSubmit,
      required this.columns,
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
        Directionality(
          textDirection: TextDirection.rtl,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isShowFilter = !isShowFilter;
              });
            },
            icon: Icon(isShowFilter ? Icons.expand_more : Icons.expand_less),
            label: const Divider(),
          ),
        ),
        const SizedBox(
          height: 10,
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
                      .map<Widget>((column) => formFilter(column))
                      .toList(),
                ),
                if (widget.onSubmit != null)
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                        onPressed: () {
                          if (_key.currentState!.validate() &&
                              widget.onSubmit != null) {
                            _key.currentState!.save();
                            widget.onSubmit!(controller.decoratedFilter);
                          }
                        },
                        child: const Text('Cari')),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget formFilter(TableColumn column) {
    switch (column.type) {
      case 'string':
        return textFilter(column);
      case 'integer':
      case 'float':
      case 'decimal':
      case 'money':
      case 'percentage':
        return numberFilter(column);
      case 'date':
      case 'datetime':
        return dateFilter(column);
      case 'enum':
        return enumFilter(column);
      case 'link':
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

  String decorateTimeRange(DateTimeRange range, String type) {
    if (type == 'date') {
      return [
        Date.parsingDateTime(range.start).toIso8601String(),
        Date.parsingDateTime(range.end).toIso8601String()
      ].join(',');
    } else {
      return [range.start.toIso8601String(), range.end.toIso8601String()]
          .join(',');
    }
  }

  Widget dateFilter(TableColumn column) {
    return SizedBox(
      width: 300,
      height: 90,
      child: DateRangePicker(
        label: Text(column.name, style: _labelStyle),
        key: ValueKey(column.key),
        canRemove: true,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          controller.setFilter(
              column.key, 'btw', decorateTimeRange(value, column.type));
        },
      ),
    );
  }

  Widget enumFilter(TableColumn column) {
    final enumList = widget.enums[column.key];
    return DropdownMenu<String>(
        width: 300,
        inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.all(12), border: OutlineInputBorder()),
        key: ValueKey(column.key),
        label: Text(
          column.name,
          style: _labelStyle,
        ),
        onSelected: (String? value) {
          if (value == null || value.isEmpty) {
            controller.removeFilter(column.key);
            return;
          }
          controller.setFilter(column.key, 'eq', value);
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
      height: 90,
      child: TextFormField(
        key: ValueKey(column.key),
        onSaved: (newValue) {
          if (newValue == null || newValue.isEmpty) {
            controller.removeFilter(column.key);
            return;
          }
          controller.setFilter(column.key, 'like', newValue);
        },
        onChanged: (newValue) {
          if (newValue.isEmpty) {
            controller.removeFilter(column.key);
            return;
          }
          controller.setFilter(column.key, 'like', newValue);
        },
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            label: Text(column.name, style: _labelStyle),
            border: const OutlineInputBorder()),
      ),
    );
  }

  Widget linkFilter(TableColumn column) {
    final attributes = column.attributeKey.split('.');
    return SizedBox(
      width: 300,
      height: 90,
      child: AsyncDropdownFormField(
        label: Text(column.name, style: _labelStyle),
        multiple: true,
        request: (server, page, searchText) =>
            server.get(column.path ?? '', queryParam: {
          'search_text': searchText,
          'fields[${attributes[0]}]': attributes[1],
          'page[page]': page.toString(),
          'page[limit]': '20'
        }),
        attributeKey: attributes[1],
        onChanged: (value) {
          if (value != null && value.isNotEmpty) {
            final decoratedValue = value
                .map<String>((e) => e.getValueAsString())
                .toList()
                .join(',');
            controller.setFilter(column.key, 'eq', decoratedValue);
          } else {
            controller.removeFilter(column.key);
          }
        },
      ),
    );
  }

  void comparisonChanged(column) {
    setState(() {
      final comparison = _textController['${column.key}-comparison'].text;
      final value1 = _textController['${column.key}-val1'].text;
      final value2 = _textController['${column.key}-val2'].text;
      if (comparison.isEmpty) {
        controller.removeFilter(column.key);
        return;
      }
      if (comparison == 'btw' && value1.isNotEmpty && value2.isNotEmpty) {
        controller.setFilter(column.key, comparison, '$value1,$value2');
      } else if (comparison != 'btw' && value1.isNotEmpty) {
        controller.setFilter(column.key, comparison, value1);
      }
    });
  }

  Widget numberFilter(TableColumn column) {
    _textController['${column.key}-val1'] = TextEditingController();
    _textController['${column.key}-val2'] = TextEditingController();
    _textController['${column.key}-comparison'] = TextEditingController();

    return SizedBox(
      width: _numComparison[column.key] == 'btw' ? 450 : 310,
      height: 90,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: DropdownMenu<String>(
                width: 120,
                onSelected: (value) {
                  setState(() {
                    _numComparison[column.key] = value;
                  });
                  comparisonChanged(column);
                },
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                controller: _textController['${column.key}-comparison'],
                label: Text(column.name, style: _labelStyle),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: '', label: ''),
                  DropdownMenuEntry(value: 'eq', label: 'sama'),
                  DropdownMenuEntry(value: 'not', label: 'bukan'),
                  DropdownMenuEntry(value: 'gt', label: '>'),
                  DropdownMenuEntry(value: 'gte', label: '>='),
                  DropdownMenuEntry(value: 'lt', label: '<'),
                  DropdownMenuEntry(value: 'lte', label: '<='),
                  DropdownMenuEntry(value: 'btw', label: 'antara'),
                ]),
          ),
          Positioned(
            left: 120,
            child: SizedBox(
              width: 130,
              child: TextFormField(
                key: ValueKey('${column.key}-value1'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  comparisonChanged(column);
                },
                controller: _textController['${column.key}-val1'],
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder()),
              ),
            ),
          ),
          if (_numComparison[column.key] == 'btw')
            Positioned(
              left: 250,
              child: SizedBox(
                width: 130,
                child: TextFormField(
                  key: ValueKey('${column.key}-value2'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    comparisonChanged(column);
                  },
                  controller: _textController['${column.key}-val2'],
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder()),
                ),
              ),
            ),
          Positioned(
            right: 0,
            child: IconButton.filled(
              onPressed: () {
                _textController['${column.key}-val1'].text = '';
                _textController['${column.key}-val2'].text = '';
                _textController['${column.key}-comparison'].text = '';
              },
              icon: const Icon(Icons.close),
              // color: colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }
}

class TableFilterFormController extends ChangeNotifier {
  Map<String, Map<String, dynamic>> filter = {};

  void setFilter(String key, String comparison, dynamic value) {
    if (filter[key] == null) {
      filter[key] = {};
    }
    filter[key]![comparison] = value;
    notifyListeners();
  }

  void removeFilter(String key) {
    filter.remove(key);
    notifyListeners();
  }

  Map get decoratedFilter => _decoratedFilter();

  Map _decoratedFilter() {
    Map newFilter = {};
    filter.forEach((key, Map values) {
      values.forEach((comparison, value) {
        newFilter['filter[$key][$comparison]'] = value;
      });
    });
    return newFilter;
  }
}