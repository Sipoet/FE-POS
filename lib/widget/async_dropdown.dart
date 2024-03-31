library dropdown_remote_multiple_menu;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
export 'package:fe_pos/model/server.dart';

class AsyncDropdownMultiple extends StatefulWidget {
  const AsyncDropdownMultiple(
      {super.key,
      this.path,
      this.minCharSearch = 3,
      this.multiple = false,
      this.width,
      this.onChanged,
      this.request,
      this.label,
      this.attributeKey,
      this.validator,
      this.onSaved,
      this.selecteds = const []});

  final String? path;
  final String? attributeKey;
  final int minCharSearch;
  final double? width;
  final List<DropdownResult> selecteds;
  final bool multiple;
  final void Function(List<dynamic>?)? onChanged;
  final void Function(List<dynamic>?)? onSaved;
  final String? Function(List<DropdownResult>?)? validator;
  final Widget? label;
  final Future Function(Server server, int page, String searchText)? request;

  @override
  State<AsyncDropdownMultiple> createState() => _AsyncDropdownMultipleState();
}

class _AsyncDropdownMultipleState extends State<AsyncDropdownMultiple> {
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);
  late final Server server;

  @override
  void initState() {
    server = context.read<Server>();
    super.initState();
  }

  Future Function(Server server, int page, String searchText) get request =>
      widget.request ??
      (Server server, int page, String searchText) {
        return server.get(widget.path!, queryParam: {
          'search_text': searchText,
          'page[page]': page.toString(),
          'page[limit]': '100'
        });
      };

  bool compareResult(DropdownResult a, DropdownResult b) {
    return a.text == b.text;
  }

  @override
  Widget build(BuildContext context) {
    // var colorScheme = Theme.of(context).colorScheme;
    return DropdownSearch<DropdownResult>.multiSelection(
      asyncItems: getData,
      onChanged: (dropdownResults) {
        if (widget.onChanged != null) {
          widget.onChanged!(dropdownResults.map((e) => e.value).toList());
        }
      },
      onSaved: (dropdownResults) {
        if (widget.onSaved != null) {
          widget.onSaved!(dropdownResults?.map((e) => e.value).toList());
        }
      },
      validator: widget.validator,
      compareFn: compareResult,
      itemAsString: (item) => item.text,
      selectedItems: widget.selecteds,
      clearButtonProps: const ClearButtonProps(isVisible: true),
      popupProps: const PopupPropsMultiSelection.menu(
          showSearchBox: true, showSelectedItems: true),
      dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
        label: widget.label,
        border: const OutlineInputBorder(),
      )),
    );
  }

  Future<List<DropdownResult>> getData(String filter) async {
    var response = await request(server, 1, filter).onError(
        (error, stackTrace) => {
              server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: [])
            });
    if (response.statusCode == 200) {
      Map responseBody = response.data;
      return convertToOptions(responseBody['data']);
    } else {
      throw 'cant connect to server';
    }
  }

  List<DropdownResult> convertToOptions(List list) {
    final nameOf = widget.attributeKey == null
        ? (row) => row['name']
        : (row) => row['attributes'][widget.attributeKey];

    return list
        .map<DropdownResult>((row) =>
            DropdownResult(value: row['id'], raw: row, text: nameOf(row)))
        .toList();
  }
}

class AsyncDropdown extends StatefulWidget {
  const AsyncDropdown(
      {super.key,
      this.path,
      this.minCharSearch = 3,
      this.multiple = false,
      this.width,
      this.onChanged,
      this.request,
      this.label,
      this.attributeKey,
      this.validator,
      this.onSaved,
      this.selected});

  final String? path;
  final String? attributeKey;
  final int minCharSearch;
  final double? width;
  final DropdownResult? selected;
  final bool multiple;
  final void Function(DropdownResult?)? onChanged;
  final void Function(DropdownResult?)? onSaved;
  final String? Function(DropdownResult?)? validator;
  final Widget? label;
  final Future Function(Server server, int page, String searchText)? request;

  @override
  State<AsyncDropdown> createState() => _AsyncDropdownState();
}

class _AsyncDropdownState extends State<AsyncDropdown> {
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);
  late final Server server;

  @override
  void initState() {
    server = context.read<Server>();
    super.initState();
  }

  Future Function(Server server, int page, String searchText) get request =>
      widget.request ??
      (Server server, int page, String searchText) {
        return server.get(widget.path!, queryParam: {
          'search_text': searchText,
          'page[page]': page.toString(),
          'page[limit]': '20'
        });
      };

  bool compareResult(DropdownResult a, DropdownResult b) {
    return a.text == b.text;
  }

  @override
  Widget build(BuildContext context) {
    // var colorScheme = Theme.of(context).colorScheme;
    return DropdownSearch<DropdownResult>(
      asyncItems: getData,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: widget.validator,
      itemAsString: (item) => item.text,
      selectedItem: widget.selected,
      compareFn: compareResult,
      clearButtonProps: const ClearButtonProps(isVisible: true),
      popupProps: const PopupProps.menu(
          showSearchBox: true, showSelectedItems: true, isFilterOnline: true),
      dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
        label: widget.label,
        border: const OutlineInputBorder(),
      )),
    );
  }

  Future<List<DropdownResult>> getData(String filter) async {
    var response = await request(server, 1, filter).onError(
        (error, stackTrace) => {
              server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: [])
            });
    if (response.statusCode == 200) {
      Map responseBody = response.data;
      return convertToOptions(responseBody['data']);
    } else {
      throw 'cant connect to server';
    }
  }

  List<DropdownResult> convertToOptions(List list) {
    final nameOf = widget.attributeKey == null
        ? (row) => row['name']
        : (row) => row['attributes'][widget.attributeKey];

    return list
        .map<DropdownResult>((row) =>
            DropdownResult(value: row['id'], raw: row, text: nameOf(row)))
        .toList();
  }
}

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
