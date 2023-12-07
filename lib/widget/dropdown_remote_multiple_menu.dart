library dropdown_remote_multiple_menu;

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/dropdown_remote_connection.dart';
export 'package:fe_pos/widget/dropdown_remote_connection.dart';
export 'package:fe_pos/model/server.dart';

class DropdownRemoteMultipleMenu extends StatefulWidget {
  const DropdownRemoteMultipleMenu(
      {Key? key,
      required this.path,
      this.minCharSearch = 3,
      required this.server,
      this.width = 0,
      required this.dropdownValue})
      : super(key: key);

  final String path;
  final int minCharSearch;
  final double width;
  final Server server;
  final List<String> dropdownValue;

  @override
  State<DropdownRemoteMultipleMenu> createState() =>
      _DropdownRemoteMultipleMenuState();
}

class _DropdownRemoteMultipleMenuState
    extends State<DropdownRemoteMultipleMenu> {
  final TextEditingController _controller = TextEditingController();
  var list = <DropdownMenuEntry<String>>[];
  final notFoundSign = const DropdownMenuEntry<String>(
      label: 'Data tidak Ditemukan', value: '', enabled: false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.length >= widget.minCharSearch ||
          _controller.text.isEmpty) {
        _remoteRequestData(_controller.text);
      }
    });
  }

  void _remoteRequestData(String query) async {
    Server server = widget.server;
    DropdownRemoteConnection connection = DropdownRemoteConnection(server);
    List rawlist = await connection.getData(widget.path, query: query);
    setState(() {
      if (rawlist.isEmpty) {
        list = [notFoundSign];
      } else {
        list = rawlist.map<DropdownMenuEntry<String>>((row) {
          return DropdownMenuEntry<String>(
              label: row['name'], value: row['id']);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? width = widget.width;
    if (widget.width == 0) {
      width = null;
    }
    if (list.isEmpty && _controller.text.isEmpty) {
      _remoteRequestData('');
    }
    // List data = list
    //     .removeWhere((element) => widget.dropdownValue.contains(element.value));
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Wrap(
              children: widget.dropdownValue.map((value) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                ),
                label: Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    alignment: Alignment.centerRight,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
                onPressed: (() {
                  setState(() {
                    widget.dropdownValue.remove(value);
                  });
                }),
              ),
            );
          }).toList()),
        ),
        if (widget.dropdownValue.isNotEmpty)
          const SizedBox(
            height: 10,
          ),
        DropdownMenu<String>(
          initialSelection: '',
          width: width,
          menuHeight: 250,
          controller: _controller,
          enableFilter: false,
          enableSearch: true,
          requestFocusOnTap: true,
          onSelected: (String? value) {
            // This is called when the user selects an item.
            setState(() {
              widget.dropdownValue.add(value!);
              _controller.text = '';
            });
          },
          dropdownMenuEntries: list,
        ),
      ],
    );
  }
}
