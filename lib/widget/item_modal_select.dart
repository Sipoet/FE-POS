import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemModalSelect extends StatefulWidget {
  final List<Item> initialValue;
  const ItemModalSelect({super.key, this.initialValue = const <Item>[]});

  @override
  State<ItemModalSelect> createState() => _ItemModalSelectState();
}

class _ItemModalSelectState extends State<ItemModalSelect> {
  List<Item> values = [];
  late final Server _server;
  late final List<TableColumn> _columns;

  @override
  void initState() {
    _server = context.read()<Server>();
    super.initState();
  }

  void fetchItem() {
    _server.get('item_reports/')
  }

  @override
  Widget build(BuildContext context) {
    return SyncDataTable(
      onPageChanged: () {},
    );
  }
}
