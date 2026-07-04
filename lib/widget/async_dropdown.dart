library;

import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sortable_wrap/flutter_sortable_wrap.dart';
import 'package:provider/provider.dart';
export 'package:fe_pos/model/server.dart';
export 'package:fe_pos/tool/query_data.dart';

class MultipleDropdownController<T> extends ValueNotifier<List<T>> {
  MultipleDropdownController(super.value);

  void remove(T val, {bool notify = true}) {
    value.remove(val);
    if (notify) notifyListeners();
  }

  void removeAt(int index, {bool notify = true}) {
    value.removeAt(index);
    if (notify) notifyListeners();
  }

  void switchIndex(index1, index2) {
    T item = value[index1];
    value.removeAt(index1);
    value.insert(index2, item);
    notifyListeners();
  }

  int get valueLength => value.length;
  void clear({bool notify = true}) {
    value.clear();
    if (notify) notifyListeners();
  }
}

typedef DropdownText<T> = String Function(T model);
typedef DropdownValidator<T> = String? Function(List<T>? models);
typedef RequestRemote<T> =
    Future<QueryResponse<T>> Function(QueryRequest queryRequest);

class AsyncDropdownMultiple<T extends Model> extends StatefulWidget {
  const AsyncDropdownMultiple({
    super.key,
    this.path,
    this.delayedSearch = const Duration(milliseconds: 500),
    this.width,
    this.onChanged,
    this.request,
    this.label,
    this.attributeKey,
    this.validator,
    this.onSaved,
    this.readOnly,
    this.focusNode,
    this.selectedDisplayLimit = 6,
    this.recordLimit = 10,
    required this.textOnSearch,
    this.textOnSelected,
    this.compareValue,
    this.controller,
    this.isDense,
    required this.modelClass,
    this.selecteds,
  });

  final String? path;
  final MultipleDropdownController<T>? controller;
  final ModelClass<T> modelClass;
  final String? attributeKey;
  final Duration delayedSearch;
  final int recordLimit;
  final double? width;
  final bool? isDense;
  final bool? readOnly;
  final List<T>? selecteds;
  final int selectedDisplayLimit;
  final FocusNode? focusNode;
  final void Function(List<T> models)? onChanged;
  final void Function(List<T>? models)? onSaved;
  final DropdownValidator<T>? validator;
  final DropdownText<T> textOnSearch;
  final DropdownText<T>? textOnSelected;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final RequestRemote<T>? request;

  @override
  State<AsyncDropdownMultiple<T>> createState() =>
      _AsyncDropdownMultipleState<T>();
}

class _AsyncDropdownMultipleState<T extends Model>
    extends State<AsyncDropdownMultiple<T>>
    with DefaultResponse, PlatformChecker {
  final notFoundSign = const DropdownMenuEntry<String>(
    label: 'Data tidak Ditemukan',
    value: '',
    enabled: false,
  );
  late final Server server;
  CancelToken _cancelToken = CancelToken();
  late final String Function(T) textFormat;
  late final MultipleDropdownController<T> controller;

  @override
  void initState() {
    controller =
        widget.controller ??
        MultipleDropdownController<T>(widget.selecteds ?? []);
    server = context.read<Server>();
    _focusNode = widget.focusNode ?? FocusNode();

    textFormat = widget.textOnSelected ?? widget.textOnSearch;
    super.initState();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  RequestRemote<T> get request =>
      widget.request ??
      (QueryRequest queryRequest) {
        _cancelToken = queryRequest.cancelToken!;
        return server
            .get(
              widget.path!,
              queryParam: queryRequest.toQueryParam(),
              cancelToken: _cancelToken,
            )
            .then((response) {
              if (response.statusCode == 200) {
                final models = convertToOptions(
                  response.data['data'],
                  response.data['included'],
                );
                return QueryResponse<T>(
                  models: models,
                  metadata: response.data['meta'],
                );
              }
              return QueryResponse<T>(models: []);
            });
      };

  bool compareResult(T a, T b) {
    if (widget.compareValue == null) {
      return widget.textOnSearch(a) == widget.textOnSearch(b);
    } else {
      return widget.compareValue!(a, b);
    }
  }

  late final FocusNode _focusNode;
  List<Widget> pills = [];
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return DropdownSearch<T>.multiSelection(
      items: getData,
      onChanged: (value) {
        setState(() {
          controller.value = value;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(controller.value);
        }
      },
      onSaved: widget.onSaved,
      validator: widget.validator,
      compareFn: compareResult,
      itemAsString: widget.textOnSearch,
      selectedItems: controller.value,
      onBeforePopupOpening: (selItems) {
        if (widget.readOnly == true) {
          return Future.value(false);
        }
        return Future.delayed(Durations.long1, () {
          if (_focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
          return true;
        });
      },
      suffixProps: const DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(isVisible: true),
      ),
      dropdownBuilder: (context, selectedItems) {
        controller.value = selectedItems;
        pills = controller.value.mapIndexed<Widget>((index, item) {
          if (index >= widget.selectedDisplayLimit) {
            return SizedBox();
          }
          return Container(
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
                    textFormat(item),
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final result = controller.value.remove(item);
                      if (result == false) {
                        debugPrint(
                          'item ${item.id.toString()} failed to remove.',
                        );
                      }

                      if (widget.onChanged != null) {
                        widget.onChanged!(controller.value);
                      }
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          );
        }).toList();
        return Tooltip(
          message: controller.value.map(textFormat).join(', '),
          child: SortableWrap(
            onSorted: (int oldIndex, int newIndex) {
              setState(() {
                controller.switchIndex(oldIndex, newIndex);
              });
            },
            spacing: 10,
            runSpacing: 15,
            children: [
              ...pills,
              if (controller.valueLength > widget.selectedDisplayLimit)
                IgnorePointer(
                  ignoring: true,
                  child: Text(
                    '.....',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
      popupProps: isMobile()
          ? PopupPropsMultiSelection.dialog(
              searchDelay: widget.delayedSearch,
              searchFieldProps: TextFieldProps(focusNode: _focusNode),
              onItemAdded: (selectedItems, addedItem) {
                _focusNode.requestFocus();
              },
              showSearchBox: true,
              showSelectedItems: true,
              disableFilter: true,
              infiniteScrollProps: InfiniteScrollProps(
                loadingMoreBuilder: (p0, loadedItems) => Text('Loading data'),
                loadProps: LoadProps(skip: 0, take: widget.recordLimit),
              ),
            )
          : PopupPropsMultiSelection.menu(
              searchDelay: widget.delayedSearch,
              searchFieldProps: TextFieldProps(focusNode: _focusNode),
              onItemAdded: (selectedItems, addedItem) {
                _focusNode.requestFocus();
              },
              showSearchBox: true,
              showSelectedItems: true,
              disableFilter: true,
              infiniteScrollProps: InfiniteScrollProps(
                loadingMoreBuilder: (p0, loadedItems) => Text('Loading data'),
                loadProps: LoadProps(skip: 0, take: widget.recordLimit),
              ),
            ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          label: widget.label,
          isDense: widget.isDense,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<List<T>> getData(String filter, LoadProps? prop) {
    int page = (prop!.skip / widget.recordLimit).round() + 1;
    if (widget.path == null && widget.request == null) {
      return widget.modelClass
          .finds(
            server,
            QueryRequest(
              cancelToken: _cancelToken,
              searchText: filter,
              page: page,
              limit: widget.recordLimit,
            ),
          )
          .then((response) => response.models);
    }
    final QueryRequest queryRequest = QueryRequest(
      page: page,
      limit: widget.recordLimit,
      searchText: filter,
      cancelToken: _cancelToken,
    );
    return request(queryRequest)
        .then((response) => response.models)
        .onError(
          (error, stackTrace) =>
              defaultErrorResponse(error: error, valueWhenError: []),
        );
  }

  List<T> convertToOptions(List list, List relationships) {
    return list
        .map<T>(
          (row) => widget.modelClass.fromJson(row, included: relationships),
        )
        .toList();
  }
}

class AsyncDropdown<T extends Model> extends StatefulWidget {
  const AsyncDropdown({
    super.key,
    this.path,
    this.allowClear = true,
    this.delayedSearch = const Duration(seconds: 1),
    this.width,
    this.onChanged,
    this.request,
    this.label,
    this.attributeKey,
    this.validator,
    this.onSaved,
    this.isDense,
    this.readOnly,
    this.focusNode,
    this.selectedDisplayLimit = 6,
    this.recordLimit = 10,
    this.textOnSearch,
    this.textOnSelected,
    this.compareValue,
    this.notifier,
    this.isShowItemDescription = false,
    this.valueFallback,
    this.searchItemDescription,
    required this.modelClass,
    this.selected,
  });

  final String? path;
  final String? attributeKey;
  final Duration delayedSearch;
  final int recordLimit;
  final double? width;
  final T? selected;
  final bool allowClear;
  final bool? isDense;
  final bool? readOnly;
  final bool isShowItemDescription;
  final ChangeNotifier? notifier;
  final ValueCallBack<T>? valueFallback;
  final FocusNode? focusNode;
  final int selectedDisplayLimit;
  final void Function(T? model)? onChanged;
  final void Function(T? model)? onSaved;
  final String? Function(T? model)? validator;
  final DropdownText<T>? textOnSearch;
  final DropdownText<T>? textOnSelected;
  final DropdownText<T>? searchItemDescription;
  final ModelClass<T> modelClass;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final RequestRemote<T>? request;

  @override
  State<AsyncDropdown<T>> createState() => _AsyncDropdownState<T>();
}

class _AsyncDropdownState<T extends Model> extends State<AsyncDropdown<T>>
    with DefaultResponse, PlatformChecker {
  final notFoundSign = const DropdownMenuEntry<String>(
    label: 'Data tidak Ditemukan',
    value: '',
    enabled: false,
  );
  late final Server server;
  CancelToken _cancelToken = CancelToken();
  late final FocusNode _focusNode;
  T? initialSelected;
  late DropdownText<T> textOnSearch;
  @override
  void initState() {
    textOnSearch = widget.textOnSearch ?? (T value) => value.modelValue;
    server = context.read<Server>();
    initialSelected = widget.selected ?? widget.valueFallback?.call();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.notifier?.addListener(refreshDropdown);
    super.initState();
  }

  void refreshDropdown() {
    setState(() {
      initialSelected = widget.valueFallback?.call();
    });
  }

  @override
  void dispose() {
    widget.notifier?.removeListener(refreshDropdown);
    _cancelToken.cancel();
    super.dispose();
  }

  RequestRemote<T> get request =>
      widget.request ??
      (QueryRequest queryRequest) {
        _cancelToken = queryRequest.cancelToken!;
        return server
            .get(
              widget.path!,
              queryParam: queryRequest.toQueryParam(),
              cancelToken: _cancelToken,
            )
            .then((response) {
              if (response.statusCode == 200) {
                final models = convertToOptions(
                  response.data['data'],
                  response.data['included'] ?? [],
                );
                return QueryResponse<T>(
                  models: models,
                  metadata: response.data['meta'],
                );
              }
              return QueryResponse<T>(models: []);
            });
      };

  bool compareResult(T a, T b) {
    if (widget.compareValue == null) {
      return textOnSearch(a) == textOnSearch(b);
    } else {
      return widget.compareValue!(a, b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textFormat =
        widget.textOnSelected ?? widget.textOnSearch ?? textOnSearch;
    return DropdownSearch<T>(
      key: ValueKey(initialSelected),
      items: getData,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: widget.validator,
      compareFn: compareResult,
      itemAsString: textOnSearch,
      selectedItem: initialSelected,
      suffixProps: DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(isVisible: widget.allowClear),
      ),
      dropdownBuilder: (context, selectedItem) {
        if (selectedItem == null) {
          return const SizedBox();
        }
        return SelectableText(textFormat(selectedItem));
      },
      onBeforePopupOpening: (item) {
        if (widget.readOnly == true) {
          return Future.value(false);
        }
        return Future.value(true);
      },
      popupProps: isMobile()
          ? PopupProps.dialog(
              searchDelay: widget.delayedSearch,
              searchFieldProps: TextFieldProps(focusNode: _focusNode),
              onItemsLoaded: (selectedItems) => Future.delayed(
                Durations.short1,
                () => _focusNode.requestFocus(),
              ),
              itemBuilder: widget.isShowItemDescription ? itemBuilder : null,
              showSearchBox: true,
              showSelectedItems: true,
              disableFilter: true,
              infiniteScrollProps: InfiniteScrollProps(
                loadProps: LoadProps(skip: 0, take: widget.recordLimit),
              ),
            )
          : PopupProps.menu(
              searchDelay: widget.delayedSearch,
              searchFieldProps: TextFieldProps(focusNode: _focusNode),
              onItemsLoaded: (selectedItems) =>
                  Future.delayed(Durations.short1, () {
                    _focusNode.requestFocus();
                  }),
              showSearchBox: true,
              showSelectedItems: true,
              disableFilter: true,
              itemBuilder: widget.isShowItemDescription ? itemBuilder : null,
              infiniteScrollProps: InfiniteScrollProps(
                loadProps: LoadProps(skip: 0, take: widget.recordLimit),
              ),
            ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          label: widget.label,
          isDense: widget.isDense,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget itemBuilder(
    BuildContext context,
    T item,
    bool isDisabled,
    bool isSelected,
  ) => ListTile(
    title: Text(
      textOnSearch(item),
      style: TextStyle(
        color: textColor(isSelected, isDisabled),
        fontWeight: .w500,
      ),
    ),
    subtitle: Text(
      widget.searchItemDescription?.call(item) ?? item.valueDescription ?? '',
      style: TextStyle(
        color: textColor(isSelected, isDisabled),
        fontStyle: .italic,
        fontSize: 12,
      ),
    ),
  );

  Color textColor(bool isSelected, bool isDisabled) {
    if (isDisabled) {
      return Colors.grey.shade700;
    }
    return isSelected ? Colors.green.shade700 : Colors.black;
  }

  Future<List<T>> getData(String filter, LoadProps? prop) {
    int page = (prop!.skip / widget.recordLimit).round() + 1;
    if (widget.path == null && widget.request == null) {
      return widget.modelClass
          .finds(
            server,
            QueryRequest(
              cancelToken: _cancelToken,
              searchText: filter,
              page: page,
              limit: widget.recordLimit,
            ),
          )
          .then((response) => response.models);
    }
    final QueryRequest queryRequest = QueryRequest(
      page: page,
      limit: widget.recordLimit,
      searchText: filter,
      cancelToken: _cancelToken,
    );
    return request(queryRequest).then(
      (response) => response.models,
      onError: (error, stackTrace) {
        debugPrint("${error.toString()}\n${stackTrace.toString()}");
        return defaultErrorResponse(error: error, valueWhenError: []);
      },
    );
  }

  List<T> convertToOptions(List list, List relationships) {
    return list
        .map<T>(
          (row) => widget.modelClass.fromJson(row, included: relationships),
        )
        .toList();
  }
}
