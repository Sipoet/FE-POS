library;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
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
  final void Function(List<T>)? onChanged;
  final void Function(List<T>?)? onSaved;
  final String? Function(List<T>?)? validator;
  final String Function(T) textOnSearch;
  final String Function(T)? textOnSelected;
  final T Function(Map<String, dynamic>, {List included}) converter;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final Future Function(
          Server server, int page, String searchText, CancelToken cancelToken)?
      request;

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

  Future Function(
          Server server, int page, String searchText, CancelToken cancelToken)
      get request =>
          widget.request ??
          (Server server, int page, String searchText,
              CancelToken cancelToken) {
            _cancelToken = CancelToken();
            return server.get(widget.path!,
                queryParam: {
                  'search_text': searchText,
                  'page[page]': page.toString(),
                  'page[limit]': widget.recordLimit.toString(),
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
        final textFormat = widget.textOnSelected ?? widget.textOnSearch;
        final lengthItems = selectedItems.length <= widget.selectedDisplayLimit
            ? selectedItems.length
            : widget.selectedDisplayLimit + 1;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List<Widget>.generate(lengthItems, (index) {
            if (index == widget.selectedDisplayLimit) {
              return const Text('.....');
            }
            final selectedItem = selectedItems[index];
            final pillWidget = Container(
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
                    textFormat(selectedItem),
                    style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black),
                  )),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          selectedItems.remove(selectedItem);
                          if (widget.onChanged != null) {
                            widget.onChanged!(selectedItems);
                          }
                        });
                      },
                      icon: const Icon(Icons.close_rounded))
                ],
              ),
            );
            return Draggable<T>(
              data: selectedItem,
              childWhenDragging: const SizedBox(
                width: 10,
              ),
              feedback: pillWidget,
              child: DragTarget<T>(builder: (
                BuildContext context,
                List<dynamic> accepted,
                List<dynamic> rejected,
              ) {
                return pillWidget;
              }, onAcceptWithDetails: (DragTargetDetails<T> details) {
                setState(() {
                  final index = selectedItems.indexOf(selectedItem);
                  selectedItems.removeAt(selectedItems.indexOf(details.data));
                  selectedItems.insert(index, details.data);
                });
              }),
            );
          }).toList(),
        );
      },
      popupProps: PopupPropsMultiSelection.menu(
        searchDelay: widget.delayedSearch,
        searchFieldProps: TextFieldProps(
          focusNode: _focusNode,
        ),
        onItemAdded: (selectedItems, addedItem) => _focusNode.requestFocus(),
        showSearchBox: true,
        showSelectedItems: true,
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
    debugPrint(
        'take ${prop?.take.toString()}, skip ${prop?.skip.toString()}, page ${page.toString()}');
    var response = await request(server, page, filter, _cancelToken).onError(
        (error, stackTrace) =>
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
  final void Function(T?)? onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final String Function(T) textOnSearch;
  final String Function(T)? textOnSelected;
  final T Function(Map<String, dynamic>, {List included}) converter;
  final Widget? label;
  final bool Function(T, T)? compareValue;
  final Future Function(
          Server server, int page, String searchText, CancelToken cancelToken)?
      request;

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

  Future Function(
          Server server, int page, String searchText, CancelToken cancelToken)
      get request =>
          widget.request ??
          (Server server, int page, String searchText,
              CancelToken cancelToken) {
            _cancelToken = CancelToken();
            return server.get(widget.path!,
                queryParam: {
                  'search_text': searchText,
                  'page[page]': page.toString(),
                  'page[limit]': widget.recordLimit.toString(),
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
    var response = await request(server, page, filter, _cancelToken).onError(
        (error, stackTrace) =>
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
