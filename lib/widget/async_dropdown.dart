library dropdown_remote_multiple_menu;

import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
export 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
export 'package:fe_pos/model/server.dart';

class AsyncDropdownFormField extends FormField<List<BsSelectBoxOption>?> {
  AsyncDropdownFormField({
    super.key,
    ValueChanged<List<BsSelectBoxOption>?>? onChanged,
    List<BsSelectBoxOption>? selected,
    String? path,
    String? attributeKey,
    BsSelectBoxController? controller,
    super.validator,
    bool multiple = false,
    Widget? label,
    Future Function(Server server, int offset, String searchText)? request,
    super.autovalidateMode,
  }) : super(
          initialValue: selected ?? controller?.getSelectedAll(),
          builder: (state) {
            void onChangedHandler(List<BsSelectBoxOption>? value) {
              state.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) label,
                  AsyncDropdown(
                    selected: selected,
                    attributeKey: attributeKey,
                    path: path,
                    multiple: multiple,
                    request: request,
                    controller: controller,
                    side: state.hasError
                        ? const BorderSide(color: Colors.red, width: 1)
                        : BorderSide(color: Colors.grey.shade300, width: 1),
                    onChanged: onChangedHandler,
                  ),
                  if (state.hasError) ...[
                    Text(
                      state.errorText!,
                      style: const TextStyle(fontSize: 15, color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          },
        );
}

class AsyncDropdown extends StatefulWidget {
  const AsyncDropdown(
      {Key? key,
      this.side =
          const BorderSide(color: Color.fromARGB(255, 224, 224, 224), width: 1),
      this.path,
      this.controller,
      this.minCharSearch = 3,
      this.multiple = false,
      this.width,
      this.onChanged,
      this.request,
      this.attributeKey,
      this.selected})
      : super(key: key);

  final String? path;
  final String? attributeKey;
  final int minCharSearch;
  final double? width;
  final BsSelectBoxController? controller;
  final List<BsSelectBoxOption>? selected;
  final bool multiple;
  final void Function(List<BsSelectBoxOption>)? onChanged;
  final BorderSide side;
  final Future Function(Server server, int offset, String searchText)? request;

  @override
  State<AsyncDropdown> createState() => _AsyncDropdownState();
}

class _AsyncDropdownState extends State<AsyncDropdown> {
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);
  late final Server server;
  late final BsSelectBoxController _controller;

  @override
  void initState() {
    var sessionState = context.read<SessionState>();
    server = sessionState.server;
    _controller = widget.controller ??
        BsSelectBoxController(
            multiple: widget.multiple,
            processing: true,
            selected: widget.selected);
    super.initState();
  }

  Future Function(Server server, int page, String searchText) get request =>
      widget.request ??
      (Server server, int offset, String searchText) {
        return server.get(widget.path!, queryParam: {
          'search_text': searchText,
          'page[offset]': offset.toString(),
          'page[limit]': '100'
        });
      };

  @override
  void didUpdateWidget(covariant AsyncDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller = widget.controller ??
          BsSelectBoxController(
              multiple: widget.multiple,
              processing: true,
              selected: widget.selected);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var colorScheme = Theme.of(context).colorScheme;
    return BsSelectBox(
      searchable: true,
      onChange: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(_controller.getSelectedAll());
        }
      },
      size: const BsSelectBoxSize(maxHeight: 200),
      style: BsSelectBoxStyle(
          border: Border.fromBorderSide(widget.side),
          focusedBoxShadow: const [
            BoxShadow(color: Colors.blue, blurRadius: 3, spreadRadius: 0)
          ],
          focusedBorder: const Border.fromBorderSide(
              BorderSide(color: Colors.blue, width: 1))),
      controller: _controller,
      serverSide: (params) async {
        var list = await getData(query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: list);
      },
    );
  }

  Future<List<BsSelectBoxOption>> getData({String query = ''}) async {
    var response = await request(server, 0, query).onError(
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

  List<BsSelectBoxOption> convertToOptions(List list) {
    final nameOf = widget.attributeKey == null
        ? (row) => row['name']
        : (row) => row['attributes'][widget.attributeKey];

    return list
        .map<BsSelectBoxOption>((row) => BsSelectBoxOption(
              value: row['id'],
              searchable: "${row['id']} ${row['name']}",
              other: row,
              text: Text(
                nameOf(row),
                softWrap: true,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ))
        .toList();
  }
}
