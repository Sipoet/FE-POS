library dropdown_remote_menu;

import 'package:flutter/material.dart';
import 'package:fe_pos/components/server.dart';
import 'package:fe_pos/components/dropdown_remote_connection.dart';
export 'package:fe_pos/components/dropdown_remote_connection.dart';
export 'package:fe_pos/components/server.dart';
export 'dart:developer';
export 'dart:convert';

class DropdownRemoteMenu extends StatefulWidget {
  DropdownRemoteMenu(
      {Key? key,
      required this.path,
      this.minCharSearch = 3,
      required this.server,
      this.width = 0,
      this.dropdownValue = ''})
      : super(key: key);

  final String path;
  final int minCharSearch;
  final double width;
  final Server server;
  String dropdownValue;

  @override
  State<DropdownRemoteMenu> createState() => _DropdownRemoteMenuState();
}

class _DropdownRemoteMenuState extends State<DropdownRemoteMenu> {
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
    if (_controller.text.isEmpty) {
      widget.dropdownValue = '';
    }
    if (list.isEmpty && _controller.text.isEmpty) {
      _remoteRequestData('');
    }
    return DropdownMenu<String>(
      initialSelection: widget.dropdownValue,
      width: width,
      menuHeight: 250,
      controller: _controller,
      enableFilter: false,
      enableSearch: true,
      requestFocusOnTap: true,
      onSelected: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          widget.dropdownValue = value!;
        });
      },
      dropdownMenuEntries: list,
    );
  }
}
