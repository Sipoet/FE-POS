import 'dart:async';

import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sortable_wrap/flutter_sortable_wrap.dart';

abstract class DropdownOption<T extends Object> {
  FutureOr<Iterable<T>> optionsBuilder(TextEditingValue textEditingValue);
}

class ModelAsyncDropdownOption<T extends Model> extends DropdownOption<T> {
  final ModelClass<T> modelClass;
  final Server server;
  ModelAsyncDropdownOption({required this.modelClass, required this.server});
  @override
  FutureOr<Iterable<T>> optionsBuilder(TextEditingValue textEditingValue) {
    final queryRequest = QueryRequest(
      page: 1,
      limit: 20,
      searchText: textEditingValue.text,
    );
    return modelClass
        .finds(server, queryRequest)
        .then((result) => result.models);
  }
}

class AsyncDropdownOption<T extends Object> extends DropdownOption<T> {
  final Future<Iterable<T>> Function(QueryRequest) request;
  AsyncDropdownOption({required this.request});
  @override
  FutureOr<Iterable<T>> optionsBuilder(TextEditingValue textEditingValue) {
    final queryRequest = QueryRequest(
      page: 1,
      limit: 20,
      searchText: textEditingValue.text,
    );
    return request(queryRequest);
  }
}

class LocalDropdownOption<T extends Object> extends DropdownOption<T> {
  final Iterable<T> items;
  LocalDropdownOption({required this.items});
  @override
  FutureOr<Iterable<T>> optionsBuilder(TextEditingValue textEditingValue) {
    return items;
  }
}

typedef StateSetter = void Function(void Function());

abstract class DropdownValue<T extends Object> {
  final TextConverted<T> selectionText;
  DropdownValue({required this.selectionText});
  Widget fieldViewBuilder({
    required BuildContext context,
    required TextEditingController textController,
    required FocusNode focusNode,
    Widget? label,
    required void Function() onFieldSubmitted,
    bool? isDense,
  });

  void onDataSelected(T value);
}

class SingleDropdownValue<T extends Object> extends DropdownValue<T> {
  T? _selected;
  AllegraSingleDropdownController? controller;
  final void Function(T? value)? onChanged;

  final void Function(T? value)? onSaved;

  final String? Function(T? value)? validator;
  SingleDropdownValue({
    T? initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.controller,
    required super.selectionText,
  }) : _selected = initialValue;

  @override
  void onDataSelected(value) {
    _selected = value;
    controller?.setValue(value);
    if (onChanged != null) {
      onChanged!(_selected);
    }
  }

  void removeSelected() {
    _selected = null;
    controller?.clear(notify: false);
  }

  @override
  Widget fieldViewBuilder({
    required BuildContext context,
    required TextEditingController textController,
    required FocusNode focusNode,
    Widget? label,
    required void Function() onFieldSubmitted,
    bool? isDense,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => TextFormField(
        controller: textController,
        focusNode: focusNode,
        onFieldSubmitted: (value) {
          onFieldSubmitted();
        },
        decoration: InputDecoration(
          prefix: _decorateSelected(),
          border: OutlineInputBorder(),
          label: label,
          isDense: isDense,
          suffix: _selected != null
              ? IconButton(onPressed: removeSelected, icon: Icon(Icons.close))
              : null,
        ),
      ),
    );
  }

  Widget? _decorateSelected() {
    if (_selected == null) {
      return null;
    }
    String text = selectionText(_selected!);
    return Text(
      text,
      style: TextStyle(fontStyle: .italic, fontWeight: .w500),
    );
  }
}

class MultipleDropdownValue<T extends Object> extends DropdownValue<T> {
  List<T> _selecteds;
  AllegraMultipleDropdownController<T>? controller;
  int? pillsLimit;

  final void Function(List<T> value)? onChanged;

  final void Function(List<T> value)? onSaved;

  final String? Function(List<T> value)? validator;
  MultipleDropdownValue({
    List<T>? initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.pillsLimit,
    this.controller,
    required super.selectionText,
  }) : _selecteds = initialValue ?? [];
  @override
  Widget fieldViewBuilder({
    required BuildContext context,
    required TextEditingController textController,
    required FocusNode focusNode,
    Widget? label,
    required void Function() onFieldSubmitted,
    bool? isDense,
  }) {
    if (_selecteds.isEmpty && (controller?.value.isNotEmpty ?? false)) {
      _selecteds = controller!.value;
    }
    controller ??= AllegraMultipleDropdownController<T>(value: _selecteds);
    controller?.addListener(() {
      if (onChanged != null) {
        onChanged!(controller!.value);
      }
    });
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.grey.shade600,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        margin: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            spacing: 5,
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            mainAxisAlignment: .start,
            children: [
              if (label != null && controller!.value.isEmpty) label,
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Flexible(
                    child: Pills<T>(
                      controller: controller!,
                      selectionText: selectionText,
                      pillsLimit: pillsLimit,
                    ),
                  ),
                  if (_selecteds.isNotEmpty)
                    IconButton(
                      onPressed: () => setState(removeAllSelected),
                      icon: Icon(Icons.close),
                    ),
                ],
              ),
              TextFormField(
                controller: textController,
                focusNode: focusNode,
                onFieldSubmitted: (value) {
                  onFieldSubmitted();
                  Future.delayed(
                    Duration(microseconds: 100),
                    () => textController.clear(),
                  );
                },
                decoration: InputDecoration(
                  border: UnderlineInputBorder(borderSide: BorderSide.none),
                  isDense: isDense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onDataSelected(value) {
    _selecteds.add(value);
    controller?.add(value, notify: true);

    debugPrint('data selected ${_selecteds.length}');
  }

  void removeAllSelected() {
    _selecteds.clear();
    controller?.clear(notify: true);
  }
}

class Pills<T extends Object> extends StatefulWidget {
  final AllegraMultipleDropdownController<T> controller;
  final int? pillsLimit;
  final TextConverted<T> selectionText;
  const Pills({
    super.key,
    required this.controller,
    this.pillsLimit,
    required this.selectionText,
  });

  @override
  State<Pills> createState() => _PillsState<T>();
}

class _PillsState<T extends Object> extends State<Pills<T>> {
  List<T> get items => widget.controller.value;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SortableWrap(
      onSorted: (int oldIndex, int newIndex) {
        setState(() {
          T item = items[oldIndex];
          items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
      },
      spacing: 10,
      runSpacing: 10,
      children: [
        ...items.map<Widget>(
          (value) => Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.all(Radius.elliptical(10, 10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.selectionText(value),
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => removeSelected(value),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
        if (widget.pillsLimit != null && items.length > widget.pillsLimit!)
          IgnorePointer(
            ignoring: true,
            child: Text('.....', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  void removeSelected(T value) {
    setState(() {
      widget.controller.remove(value, notify: true);
    });
  }
}

typedef TextConverted<T> = String Function(T value);

class AllegraDropdown<T extends Object> extends StatefulWidget {
  final TextConverted<T>? searchText;

  final DropdownOption<T> dropdownOption;
  final DropdownValue<T> dropdownValue;
  final Widget? label;
  final bool? isDense;
  const AllegraDropdown({
    super.key,
    this.searchText,
    this.label,
    this.isDense,
    required this.dropdownValue,
    required this.dropdownOption,
  });

  @override
  State<AllegraDropdown> createState() => _AllegraDropdownState<T>();
}

class _AllegraDropdownState<T extends Object>
    extends State<AllegraDropdown<T>> {
  DropdownOption<T> get dropdownOption => widget.dropdownOption;
  DropdownValue<T> get dropdownValue => widget.dropdownValue;
  TextEditingController? _textController;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      textEditingController: _textController,
      displayStringForOption: widget.searchText ?? dropdownValue.selectionText,
      fieldViewBuilder:
          (context, textController, focusNode, onFieldSubmitted) =>
              dropdownValue.fieldViewBuilder(
                context: context,
                textController: textController,
                focusNode: focusNode,
                label: widget.label,
                onFieldSubmitted: onFieldSubmitted,
                isDense: widget.isDense,
              ),
      onSelected: (option) => setState(() {
        dropdownValue.onDataSelected(option);
        Future.delayed(
          Duration(microseconds: 100),
          () => _textController?.text = ' ',
        );
      }),
      optionsBuilder: widget.dropdownOption.optionsBuilder,
    );
  }
}

abstract class AllegraFormController {
  void clear({bool notify = true});

  Object? get value;
}

class AllegraMultipleDropdownController<T extends Object> extends ChangeNotifier
    implements AllegraFormController {
  Set<T> _value = {};
  AllegraMultipleDropdownController({List<T>? value})
    : _value = value?.toSet() ?? {};

  set value(List<T> val) {
    _value = val.toSet();
    notifyListeners();
  }

  void setValue(List<T> val, {bool notify = false}) {
    _value = val.toSet();
    if (notify) {
      notifyListeners();
    }
  }

  void add(T val, {bool notify = false}) {
    _value.add(val);
    if (notify) {
      notifyListeners();
    }
  }

  void remove(T val, {bool notify = false}) {
    _value.remove(val);
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void clear({bool notify = true}) {
    _value.clear();
    if (notify) {
      notifyListeners();
    }
  }

  @override
  List<T> get value => _value.toList();
}

class AllegraSingleDropdownController<T extends Object> extends ChangeNotifier
    implements AllegraFormController {
  T? _value;
  AllegraSingleDropdownController({T? value}) : _value = value;

  set value(T val) {
    _value = val;
    notifyListeners();
  }

  void setValue(T val, {bool notify = false}) {
    _value = val;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  T? get value => _value;
  @override
  void clear({bool notify = true}) {
    _value = null;
    if (notify) {
      notifyListeners();
    }
  }
}
