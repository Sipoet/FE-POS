library;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sortable_wrap/flutter_sortable_wrap.dart';
import 'package:provider/provider.dart';
export 'package:fe_pos/model/server.dart';

class DropdownResult {
  String text;
  dynamic value;
  String? customSearch;
  Map raw;
  DropdownResult({
    required this.text,
    required this.value,
    this.customSearch,
    this.raw = const {},
  });

  String get searchableText => customSearch ?? "$value $text";
}

class AsyncDropdownMultiple<T extends Object> extends StatefulWidget {
  const AsyncDropdownMultiple(
      {super.key,
      this.path,
      this.delayedSearch = const Duration(milliseconds: 500),
      this.width,
      this.onChanged,
      this.request,
      this.label,
      this.attributeKey,
      this.validator,
      this.onSaved,
      this.focusNode,
      this.selectedDisplayLimit = 6,
      this.recordLimit = 10,
      required this.textOnSearch,
      this.textOnSelected,
      this.compareValue,
      required this.converter,
      this.selecteds = const []});

  final String? path;
  final String? attributeKey;
  final Duration delayedSearch;
  final int recordLimit;
  final double? width;
  final List<T> selecteds;
  final int selectedDisplayLimit;
  final FocusNode? focusNode;
  final void Function(List<T> models)? onChanged;
  final void Function(List<T>? models)? onSaved;
  final String? Function(List<T>? models)? validator;
  final String Function(T model) textOnSearch;
  final String Function(T model)? textOnSelected;
  final T Function(Map<String, dynamic>, {List included}) converter;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final RequestRemote? request;

  @override
  State<AsyncDropdownMultiple<T>> createState() =>
      _AsyncDropdownMultipleState<T>();
}

class _AsyncDropdownMultipleState<T extends Object>
    extends State<AsyncDropdownMultiple<T>> with DefaultResponse {
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);
  late final Server server;
  CancelToken _cancelToken = CancelToken();
  late final String Function(T) textFormat;
  @override
  void initState() {
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

  RequestRemote get request =>
      widget.request ??
      (
          {int page = 1,
          int limit = 20,
          String searchText = '',
          required CancelToken cancelToken}) {
        _cancelToken = cancelToken;
        return server.get(widget.path!,
            queryParam: {
              'search_text': searchText,
              'page[page]': page.toString(),
              'page[limit]': limit.toString(),
            },
            cancelToken: _cancelToken);
      };

  bool compareResult(T a, T b) {
    if (widget.compareValue == null) {
      return widget.textOnSearch(a) == widget.textOnSearch(b);
    } else {
      return widget.compareValue!(a, b);
    }
  }

  late final FocusNode _focusNode;
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return DropdownSearch<T>.multiSelection(
      items: (a, b) => getData(a, b),
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: widget.validator,
      compareFn: compareResult,
      itemAsString: widget.textOnSearch,
      selectedItems: widget.selecteds,
      onBeforePopupOpening: (selItems) {
        return Future.delayed(Duration.zero, () {
          if (_focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
          return true;
        });
      },
      suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true)),
      dropdownBuilder: (context, selectedItems) {
        Widget moreWidget = selectedItems.length > widget.selectedDisplayLimit
            ? IgnorePointer(
                ignoring: true,
                child: Text(
                  '.....',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : IgnorePointer(ignoring: true, child: SizedBox());
        return SortableWrap(
            onSorted: (int oldIndex, int newIndex) {
              setState(() {
                var item = selectedItems[oldIndex];
                selectedItems.removeAt(oldIndex);
                selectedItems.insert(newIndex, item);
              });
            },
            spacing: 10,
            runSpacing: 15,
            children: List<Widget>.generate(
                selectedItems.length > widget.selectedDisplayLimit
                    ? widget.selectedDisplayLimit
                    : selectedItems.length, (index) {
              final item = selectedItems[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(10, 10)),
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
                          color: Colors.black),
                    )),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            selectedItems.remove(item);
                            if (widget.onChanged != null) {
                              widget.onChanged!(selectedItems);
                            }
                          });
                        },
                        icon: const Icon(Icons.close_rounded))
                  ],
                ),
              );
            })
              ..add(moreWidget));
      },
      popupProps: PopupPropsMultiSelection.menu(
        searchDelay: widget.delayedSearch,
        searchFieldProps: TextFieldProps(
          focusNode: _focusNode,
        ),
        onItemAdded: (selectedItems, addedItem) => _focusNode.requestFocus(),
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
        label: widget.label,
        border: const OutlineInputBorder(),
      )),
    );
  }

  Future<List<T>> getData(String filter, LoadProps? prop) async {
    int page = (prop!.skip / widget.recordLimit).round() + 1;
    var response = await request(
            page: page,
            limit: widget.recordLimit,
            searchText: filter,
            cancelToken: _cancelToken)
        .onError((error, stackTrace) =>
            {defaultErrorResponse(error: error, valueWhenError: [])});
    if (response.statusCode == 200) {
      Map responseBody = response.data;
      return convertToOptions(
          responseBody['data'], responseBody['included'] ?? []);
    } else {
      throw 'cant connect to server';
    }
  }

  List<T> convertToOptions(List list, List relationships) {
    return list
        .map<T>((row) => widget.converter(row, included: relationships))
        .toList();
  }
}

typedef RequestRemote = Future Function(
    {int page, int limit, String searchText, required CancelToken cancelToken});

class AsyncDropdown<T> extends StatefulWidget {
  const AsyncDropdown(
      {super.key,
      this.path,
      this.allowClear = true,
      this.delayedSearch = const Duration(milliseconds: 500),
      this.width,
      this.onChanged,
      this.request,
      this.label,
      this.attributeKey,
      this.validator,
      this.onSaved,
      this.focusNode,
      this.selectedDisplayLimit = 6,
      this.recordLimit = 10,
      required this.textOnSearch,
      this.textOnSelected,
      this.compareValue,
      required this.converter,
      this.selected});

  final String? path;
  final String? attributeKey;
  final Duration delayedSearch;
  final int recordLimit;
  final double? width;
  final T? selected;
  final bool allowClear;
  final FocusNode? focusNode;
  final int selectedDisplayLimit;
  final void Function(T? model)? onChanged;
  final void Function(T? model)? onSaved;
  final String? Function(T? model)? validator;
  final String Function(T model) textOnSearch;
  final String Function(T model)? textOnSelected;
  final T Function(Map<String, dynamic>, {List included}) converter;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final RequestRemote? request;

  @override
  State<AsyncDropdown<T>> createState() => _AsyncDropdownState<T>();
}

class _AsyncDropdownState<T> extends State<AsyncDropdown<T>>
    with DefaultResponse {
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);
  late final Server server;
  CancelToken _cancelToken = CancelToken();
  late final FocusNode _focusNode;

  @override
  void initState() {
    server = context.read<Server>();
    _focusNode = widget.focusNode ?? FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  RequestRemote get request =>
      widget.request ??
      (
          {int page = 1,
          String searchText = '',
          int limit = 20,
          required CancelToken cancelToken}) {
        _cancelToken = cancelToken;
        return server.get(widget.path!,
            queryParam: {
              'search_text': searchText,
              'page[page]': page.toString(),
              'page[limit]': widget.recordLimit.toString(),
            },
            cancelToken: cancelToken);
      };

  bool compareResult(T a, T b) {
    if (widget.compareValue == null) {
      return widget.textOnSearch(a) == widget.textOnSearch(b);
    } else {
      return widget.compareValue!(a, b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textFormat = widget.textOnSelected ?? widget.textOnSearch;
    return DropdownSearch<T>(
      items: (a, b) => getData(a, b),
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: widget.validator,
      compareFn: compareResult,
      itemAsString: widget.textOnSearch,
      selectedItem: widget.selected,
      onBeforePopupOpening: (selItems) {
        return Future.delayed(Duration.zero, () {
          if (_focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
          return true;
        });
      },
      suffixProps: DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: widget.allowClear)),
      dropdownBuilder: (context, selectedItem) {
        if (selectedItem == null) {
          return const SizedBox();
        }
        return SelectableText(textFormat(selectedItem));
      },
      popupProps: PopupProps.menu(
        searchDelay: widget.delayedSearch,
        searchFieldProps: TextFieldProps(focusNode: _focusNode),
        onItemsLoaded: (selectedItems) => _focusNode.requestFocus(),
        showSearchBox: true,
        showSelectedItems: true,
        disableFilter: true,
        infiniteScrollProps: InfiniteScrollProps(
          loadProps: LoadProps(skip: 0, take: widget.recordLimit),
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
        label: widget.label,
        border: const OutlineInputBorder(),
      )),
    );
  }

  Future<List<T>> getData(String filter, LoadProps? prop) async {
    int page = (prop!.skip / widget.recordLimit).round() + 1;
    var response = await request(
      page: page,
      limit: widget.recordLimit,
      searchText: filter,
      cancelToken: _cancelToken,
    ).onError((error, stackTrace) =>
        {defaultErrorResponse(error: error, valueWhenError: [])});
    if (response.statusCode == 200) {
      Map responseBody = response.data;
      return convertToOptions(
          responseBody['data'], responseBody['included'] ?? []);
    } else {
      throw 'cant connect to server';
    }
  }

  List<T> convertToOptions(List list, List relationships) {
    return list
        .map<T>((row) => widget.converter(row, included: relationships))
        .toList();
  }
}
