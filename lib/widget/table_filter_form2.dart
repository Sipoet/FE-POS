import 'dart:async';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/widget/tag_select_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TableFilterForm2 extends StatefulWidget {
  final List<FilterData> initialValues;
  final List<TableColumn> columns;
  final SubmitFunct onSubmit;
  final SubmitFunct? onDownload;
  const TableFilterForm2({
    super.key,
    required this.onSubmit,
    this.onDownload,
    this.columns = const [],
    this.initialValues = const [],
  });

  @override
  State<TableFilterForm2> createState() => _TableFilterForm2State();
}

typedef SubmitFunct = void Function(List<FilterData>? filterData);

class _TableFilterForm2State extends State<TableFilterForm2> {
  final _dynamicTagController =
      DynamicTagController<DynamicTagData<FilterData>>();

  Map<String, String> humanizeKeys = {};
  Map<String, TableColumn> reverseHumanizeKeys = {};
  late final Server _server;
  static const searchTextKey = 'search_text';

  @override
  void initState() {
    _server = context.read<Server>();

    for (final column in widget.columns) {
      humanizeKeys[column.name] = column.humanizeName;
      reverseHumanizeKeys[column.humanizeName] = column;
    }
    super.initState();
  }

  FutureOr<Iterable<TagData<FilterData>>> getPossibleValue(
      TagData tagData, String searchText) {
    TableColumn? tableColumn = tagData.meta['tableColumn'];
    final filterData = tagData.value;
    debugPrint(
        'possible value key ${filterData.key} cari $searchText table column ${tableColumn?.name} ${tableColumn?.type}');
    if (tableColumn == null || tableColumn.type == TableColumnType.text) {
      return Iterable<TagData<FilterData>>.empty();
    }
    switch (tableColumn.type) {
      case TableColumnType.number:
      case TableColumnType.money:
        List<TagData<FilterData>> options = [
          TagData<FilterData>(
              label: '${tableColumn.humanizeName} kosong',
              value: ComparisonFilterData(key: tableColumn.name, value: 0)),
          TagData<FilterData>(
              label: '${tableColumn.humanizeName} ada',
              value: ComparisonFilterData(
                  key: tableColumn.name,
                  queryOperator: QueryOperator.greaterThan,
                  value: 0)),
        ];
        for (final queryOperator in QueryOperator.values) {
          final filterData = ComparisonFilterData(
              key: tableColumn.name, queryOperator: queryOperator, value: '');
          options.addAll([
            TagData<FilterData>(
                label: textOf(filterData, tableColumn), value: filterData),
            TagData<FilterData>(
                label: "${tableColumn.name} ${queryOperator.humanize()}",
                value: filterData),
          ]);
        }

        return options.where((entry) => entry.contains(searchText)).toList();

      case TableColumnType.model:
        debugPrint('masuk posible model');
        final modelName = tableColumn.inputOptions['model_name'] ?? '';
        final attributeKey = tableColumn.inputOptions['attribute_key'] ?? 'id';
        return _server.get(tableColumn.inputOptions['path'] ?? '', queryParam: {
          'search_text': searchText,
          'fields[$modelName]': attributeKey,
          'page[page]': '1',
          'page[limit]': '25',
        }).then((response) {
          if (response.statusCode != 200) {
            return <TagData<FilterData>>[];
          }

          final List data = response.data['data'] ?? [];
          return data.map<TagData<FilterData>>((row) {
            final filterData =
                ComparisonFilterData(key: tableColumn.name, value: row['id']);
            return TagData(
                searchText:
                    "${row['id']} - ${row['attributes']?[attributeKey]}",
                label: textOf(filterData, tableColumn),
                value: filterData);
          });
        });
      default:
        return Iterable<TagData<FilterData>>.empty();
    }
  }

  String textOf(FilterData filterData, TableColumn? tableColumn) {
    String operatorText = ':';
    if (filterData is ComparisonFilterData) {
      operatorText = filterData.queryOperator.humanize();
    }
    return '${tableColumn?.humanizeName} $operatorText ${filterData.humanizeValue}';
  }

  TagData<FilterData> convertToTag(String word) {
    final pattern = RegExp(
        r'^([/\w]+)\s*(\:|\=|\<|\>|\<\=|\>\=|not|lt|lte|gt|gte|contain|contains|eq|equal|like)?\s*([\w\s0-9\/]+)\s*$',
        caseSensitive: false);
    // final pattern = RegExp(r'^/api/(\w+)/(\d+)/$', caseSensitive: false);
    final match = pattern.firstMatch(word);

    if (match == null) {
      debugPrint('match null');
      return TagData(
          label: word, value: ComparisonFilterData(key: word, value: ''));
    }

    String key = 'search_text';
    QueryOperator? queryOperator;
    String? value;
    String? value2;
    TableColumn? tableColumn;
    if (match.groupCount >= 4) {
      debugPrint("match 4 ${match.group(4)}");
      value2 = match.group(4)?.trim();
    }
    if (match.groupCount >= 3) {
      debugPrint("match 3 ${match.group(3)}");
      value = match.group(3)?.trim();
    }
    if (match.groupCount >= 2) {
      debugPrint("match 2 ${match.group(2)}");
      queryOperator = QueryOperator.fromString(match.group(2) ?? ':');
    }
    if (match.groupCount >= 1) {
      debugPrint("match 1 ${match.group(1)}");
      tableColumn = reverseHumanizeKeys[match.group(1)];
      key = tableColumn?.name ?? key;
    }
    debugPrint(
        "key $key operator ${queryOperator.toString()} value $value - $value2");
    if (value2 != null) {
      final filterData = BetweenFilterData(key: key, values: [value, value2]);
      return TagData(
          label: textOf(filterData, tableColumn),
          meta: {'tableColumn': tableColumn},
          value: filterData);
    }
    final filterData = ComparisonFilterData(
        key: key,
        queryOperator: queryOperator ?? QueryOperator.equals,
        value: value);
    return TagData(
        label: textOf(filterData, tableColumn),
        meta: {'tableColumn': tableColumn},
        value: filterData);
  }

  Iterable<TagData<FilterData>> fieldOptions(List<TableColumn> columns) {
    List<TagData<FilterData>> options = [];
    for (final column in columns) {
      final columnName = column.name;
      switch (column.type) {
        case TableColumnType.money:
        case TableColumnType.number:
        case TableColumnType.date:
        case TableColumnType.datetime:
        case TableColumnType.percentage:
          options.addAll([
            TagData<FilterData>(
                label: '${column.humanizeName} kosong',
                value: ComparisonFilterData(key: column.name, value: 0)),
            TagData<FilterData>(
                label: '${column.humanizeName} ada',
                value: ComparisonFilterData(
                    key: column.name,
                    queryOperator: QueryOperator.greaterThan,
                    value: 0)),
          ]);
          options.addAll([
            ComparisonFilterData(
                key: columnName,
                queryOperator: QueryOperator.greaterThan,
                value: ''),
            ComparisonFilterData(
                key: columnName,
                queryOperator: QueryOperator.greaterThanOrEqualTo,
                value: ''),
            ComparisonFilterData(
                key: columnName,
                queryOperator: QueryOperator.lessThan,
                value: ''),
            ComparisonFilterData(
                key: columnName,
                queryOperator: QueryOperator.lessThanOrEqualTo,
                value: ''),
            BetweenFilterData(key: columnName, values: []),
            ComparisonFilterData(
                key: columnName, queryOperator: QueryOperator.not, value: ''),
            ComparisonFilterData(
                key: columnName, queryOperator: QueryOperator.equals, value: '')
          ].map((filterData) => TagData(
              label: textOf(filterData, column),
              meta: {'tableColumn': column},
              value: filterData)));

          break;
        case TableColumnType.text:
          options.addAll([
            ComparisonFilterData(
                key: columnName,
                queryOperator: QueryOperator.contains,
                value: ''),
            ComparisonFilterData(
                key: columnName, queryOperator: QueryOperator.equals, value: '')
          ].map((filterData) => TagData(
              label: textOf(filterData, column),
              meta: {'tableColumn': column},
              value: filterData)));
          break;
        default:
          final filterData = ComparisonFilterData(
              key: columnName, queryOperator: QueryOperator.equals, value: '');
          options.add(TagData(
              label: textOf(filterData, column),
              meta: {'tableColumn': column},
              value: filterData));
      }
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        FilterAutoComplete(
            controller: _dynamicTagController, columns: widget.columns),
        SizedBox(
          height: 10,
        ),
        Row(
          spacing: 10,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onSecondary,
                    backgroundColor: colorScheme.secondary),
                onPressed: () => widget.onSubmit(_dynamicTagController.getTags
                    ?.map(
                      (e) => e.data,
                    )
                    .toList()),
                child: Text('Cari')),
            if (widget.onDownload != null)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onSecondary,
                      backgroundColor: colorScheme.secondary),
                  onPressed: () =>
                      widget.onDownload!(_dynamicTagController.getTags
                          ?.map(
                            (e) => e.data,
                          )
                          .toList()),
                  child: Text('Download')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onTertiary,
                    backgroundColor: colorScheme.tertiary),
                onPressed: () {
                  _dynamicTagController.clearTags();
                },
                child: Text('Reset')),
          ],
        ),
        TagSelectField<FilterData>(
          optionBuilder: (textEditingValue) {
            TagData tag = convertToTag(textEditingValue.text);
            final searchText = textEditingValue.text.toLowerCase();
            if (searchText.trim().isEmpty) {
              return fieldOptions(widget.columns);
            } else if (tag.meta['tableColumn'] == null) {
              final columns = widget.columns
                  .where((column) =>
                      column.humanizeName.toLowerCase().contains(searchText))
                  .toList();
              return fieldOptions(columns);
            } else {
              return getPossibleValue(tag, tag.value.humanizeValue);
            }
          },
          wordToTagData: convertToTag,
          onDetectSeparator: (word, controller) {
            debugPrint('masuk detect separator');
            final tag = convertToTag(word);
            controller.addTag(tag);
            controller.controller.text = '';
          },
          textSeparators: [','],
          singleTagValidator: (object) {
            debugPrint('masuk valid tag ${object.key}');

            if (object.key != searchTextKey &&
                humanizeKeys[object.key] == null) {
              return 'key tidak valid';
            }
            if (object.key != searchTextKey &&
                object.humanizeValue.trim().isEmpty) {
              return 'filter data tidak valid';
            }
            debugPrint('valid tag ${object.key} berhasil');
            return null;
          },
        ),
      ],
    );
  }
}

class FilterAutoComplete extends StatefulWidget {
  final DynamicTagController<DynamicTagData<FilterData>> controller;
  final List<TableColumn> columns;
  final List<FilterData>? initialValues;
  const FilterAutoComplete(
      {super.key,
      this.initialValues,
      this.columns = const [],
      required this.controller});

  @override
  State<FilterAutoComplete> createState() => _FilterAutoCompleteState();
}

class _FilterAutoCompleteState extends State<FilterAutoComplete> {
  String _selectedField = 'Search Text';

  Map<String, String> humanizeKeys = {};
  Map<String, TableColumn> reverseHumanizeKeys = {};
  late final Server _server;
  late final List<String> filterFields;
  double? _textFieldWidth;

  @override
  void initState() {
    _server = context.read<Server>();
    filterFields = [
      'Search Text',
      ...widget.columns.map((e) => e.humanizeName)
    ];
    for (final column in widget.columns) {
      humanizeKeys[column.name] = column.humanizeName;
      reverseHumanizeKeys[column.humanizeName] = column;
    }
    super.initState();
  }

  List<DynamicTagData<FilterData>> getListColumns(String text) {
    return widget.columns
        .where(
          (tableColumn) => tableColumn.humanizeName
              .toLowerCase()
              .contains(text.toLowerCase()),
        )
        .map<DynamicTagData<FilterData>>((tableColumn) =>
            DynamicTagData<FilterData>("${tableColumn.humanizeName}: ",
                ComparisonFilterData(key: tableColumn.name, value: '')))
        .toList();
  }

  FutureOr<Iterable<DynamicTagData<FilterData>>> getPossibleValue(
      String key, String searchText) {
    final tableColumn = reverseHumanizeKeys[key];
    if (tableColumn == null || tableColumn.type == TableColumnType.text) {
      return <DynamicTagData<FilterData>>[];
    }
    switch (tableColumn.type) {
      case TableColumnType.number:
      case TableColumnType.money:
        final operatorDynamicData = QueryOperator.values
            .map<FilterData>((e) => ComparisonFilterData(
                key: tableColumn.name, queryOperator: e, value: ''))
            .map((filterData) => convertToTag(filterData))
            .toList();
        operatorDynamicData.addAll([
          DynamicTagData<FilterData>(
            "$key: kosong",
            ComparisonFilterData(key: tableColumn.name, value: 0),
          ),
          DynamicTagData<FilterData>(
            "$key: ada",
            ComparisonFilterData(
                key: tableColumn.name,
                queryOperator: QueryOperator.greaterThan,
                value: 0),
          ),
        ]);
        return operatorDynamicData.where((e) => e.tag.contains(searchText));
      case TableColumnType.model:
        debugPrint('masuk posible model');
        final modelName = tableColumn.inputOptions['model_name'] ?? '';
        final attributeKey = tableColumn.inputOptions['attribute_key'] ?? 'id';
        return _server.get(tableColumn.inputOptions['path'] ?? '', queryParam: {
          'search_text': searchText,
          'fields[$modelName]': attributeKey,
          'page[page]': '1',
          'page[limit]': '25',
        }).then((response) {
          if (response.statusCode != 200) {
            return <DynamicTagData<FilterData>>[];
          }

          final List data = response.data['data'] ?? [];
          return data.map<DynamicTagData<FilterData>>((row) => DynamicTagData<
                  FilterData>(
              '${tableColumn.humanizeName}: ${row['id']} - ${row['attributes'][attributeKey]}',
              ComparisonFilterData(key: tableColumn.name, value: row['id'])));
        });
      default:
        return <DynamicTagData<FilterData>>[];
    }
  }

  static const searchTextKey = 'search_text';

  String? validTag(DynamicTagData<FilterData> tag) {
    debugPrint('masuk valid tag ${tag.tag}');
    final filterData = tag.data;
    if (filterData.key != searchTextKey &&
        humanizeKeys[filterData.key] == null) {
      return 'key tidak valid';
    }
    if (filterData.key != searchTextKey &&
        filterData.humanizeValue.trim().isEmpty) {
      return 'filter data tidak valid';
    }
    return null;
  }

  DynamicTagData<FilterData> convertToTag(FilterData filterData) {
    final keyText = humanizeKeys[filterData.key] ?? 'Search Text';
    String operatorText = operatorTextOf(filterData);
    return DynamicTagData<FilterData>(
      "$keyText $operatorText ${filterData.humanizeValue}",
      filterData,
    );
  }

  String operatorTextOf(FilterData filterData) {
    if (filterData is ComparisonFilterData) {
      return filterData.queryOperator.humanize();
    } else {
      return ':';
    }
  }

  Widget pillWidget(
      {required DynamicTagData<FilterData> tag,
      required InputFieldValues inputFieldValues,
      required ColorScheme colorScheme}) {
    String operatorText = operatorTextOf(tag.data);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(20.0),
        ),
        color: colorScheme.primaryContainer,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
              text: TextSpan(
                  text: humanizeKeys[tag.data.key],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer),
                  children: [
                TextSpan(
                    text: " $operatorText ${tag.data.humanizeValue}",
                    style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.normal))
              ])),
          const SizedBox(width: 4.0),
          InkWell(
            child: const Icon(
              Icons.cancel,
              size: 14.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            onTap: () {
              inputFieldValues.onTagRemoved(tag);
            },
          )
        ],
      ),
    );
  }

  final textGlobalKey = GlobalKey();
  QueryOperator selectedOperator = QueryOperator.contains;
  Widget get filterListDropdown {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: 200,
        child: DropdownSearch<String>(
          items: (text, loadProps) {
            return filterFields;
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
          ),
          onChanged: (value) => _selectedField = value ?? _selectedField,
          selectedItem: _selectedField,
          decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                  isDense: true,
                  fillColor: Colors.grey[200],
                  filled: true,
                  border: OutlineInputBorder())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (textGlobalKey.currentContext != null) {
        final RenderBox renderBox =
            textGlobalKey.currentContext!.findRenderObject() as RenderBox;
        if (_textFieldWidth != renderBox.size.width) {
          setState(() {
            _textFieldWidth = renderBox.size.width;
          });
        }
        debugPrint('width ${_textFieldWidth.toString()}');
      }
    });
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          side: BorderSide(),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      shadowColor: Colors.transparent,
      child: Autocomplete<DynamicTagData<FilterData>>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final text = textEditingValue.text;
          debugPrint('render options');
          if (text.isEmpty) {
            return const Iterable<DynamicTagData<FilterData>>.empty();
          } else {
            return getPossibleValue(_selectedField, text);
          }
        },
        onSelected: (option) {
          if (validTag(option) == null) {
            widget.controller.onTagSubmitted(option);
          } else {
            var data = option.data;
            if (data is ComparisonFilterData) {
              selectedOperator = data.queryOperator;
            } else {
              selectedOperator = QueryOperator.equals;
            }
            debugPrint(
                'onSelected tag ${option.tag} operator ${selectedOperator.toString()}');
            widget.controller.onTagChanged(option);
          }
        },
        displayStringForOption: (option) => option.tag,
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: Container(
                width: _textFieldWidth,
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    bool isHighlight =
                        AutocompleteHighlightedOption.of(context) == index;

                    return GestureDetector(
                      onTap: () {
                        onSelected(option);
                      },
                      child: ListTile(
                        tileColor: isHighlight
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer,
                        title: Text(
                          option.tag,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (BuildContext context, textEditingController,
            focusNode, onFieldSubmitted) {
          return TextFieldTags<DynamicTagData<FilterData>>(
              textfieldTagsController: widget.controller,
              textEditingController: textEditingController,
              focusNode: focusNode,
              initialTags: widget.initialValues
                  ?.map<DynamicTagData<FilterData>>(
                      (filterData) => convertToTag(filterData))
                  .toList(),
              textSeparators: const [',', '=', '<', '<=', '>=', '>', ';'],
              validator: validTag,
              letterCase: LetterCase.normal,
              inputFieldBuilder: (BuildContext context,
                  InputFieldValues<DynamicTagData<FilterData>>
                      inputFieldValues) {
                return TextField(
                  key: textGlobalKey,
                  style: TextStyle(fontSize: 16),
                  controller: inputFieldValues.textEditingController,
                  focusNode: inputFieldValues.focusNode,
                  onEditingComplete: onFieldSubmitted,
                  onChanged: (value) {
                    final tableColumn = reverseHumanizeKeys[_selectedField];
                    late final FilterData filterData;
                    if (tableColumn != null) {
                      filterData = ComparisonFilterData(
                          key: tableColumn.name,
                          queryOperator: selectedOperator,
                          value: value.replaceAll(RegExp('[,;]'), ''));
                    } else {
                      filterData = ComparisonFilterData(
                          key: searchTextKey,
                          queryOperator: selectedOperator,
                          value: value.replaceAll(RegExp('[,;]'), ''));
                    }

                    final tagData = convertToTag(filterData);
                    inputFieldValues.onTagChanged(tagData);
                    debugPrint('on changed tag ${tagData.tag}');
                  },
                  onSubmitted: (value) {
                    debugPrint(
                        'on submitted value $value operator ${selectedOperator.toString()}');
                    if (value.trim().isEmpty) {
                      // widget.onSubmit(widget.controller.getTags
                      //     ?.map(
                      //       (e) => e.data,
                      //     )
                      //     .toList());
                      return;
                    }
                    final tableColumn = reverseHumanizeKeys[_selectedField];
                    late final FilterData filterData;
                    if (tableColumn != null) {
                      filterData = ComparisonFilterData(
                          key: tableColumn.name,
                          queryOperator: selectedOperator,
                          value: value.replaceAll(RegExp('[,;]'), ''));
                    } else {
                      filterData = ComparisonFilterData(
                          key: searchTextKey,
                          queryOperator: selectedOperator,
                          value: value.replaceAll(RegExp('[,;]'), ''));
                    }
                    final tag = convertToTag(filterData);
                    inputFieldValues.onTagSubmitted(tag);
                  },
                  decoration: InputDecoration(
                    prefixIcon: SingleChildScrollView(
                      controller: inputFieldValues.tagScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: inputFieldValues.tags
                              .map<Widget>((DynamicTagData<FilterData> tag) =>
                                  PillWidget(
                                    onRemove: () =>
                                        inputFieldValues.onTagRemoved(tag),
                                    fieldName: humanizeKeys[tag.data.key] ?? '',
                                    operatorText: operatorTextOf(tag.data),
                                    value: tag.data.humanizeValue,
                                  ))
                              .toList()
                            ..addAll([filterListDropdown, const Text(' :')])),
                    ),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    errorText: inputFieldValues.error,
                    hintText: 'Filter',
                  ),
                );
              });
        },
      ),
    );
  }
}

class PillWidget extends StatelessWidget {
  final String fieldName;
  final String operatorText;
  final String value;
  final void Function()? onRemove;
  const PillWidget({
    super.key,
    this.fieldName = '',
    this.operatorText = ':',
    this.value = '',
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(20.0),
        ),
        color: colorScheme.primaryContainer,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
              text: TextSpan(
                  text: fieldName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer),
                  children: [
                TextSpan(
                    text: " $operatorText $value",
                    style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.normal))
              ])),
          const SizedBox(width: 4.0),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.cancel,
              size: 14.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          )
        ],
      ),
    );
  }
}
