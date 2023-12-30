import 'package:fe_pos/widget/sales_report.dart';
import 'package:fe_pos/widget/item_sales_report.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _panels = <Widget>[
    SalesTodayReport(),
    ItemSalesTodayReport(
        key: ValueKey('brand'),
        groupKey: 'brand',
        limit: '5',
        label: 'Merek Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('item_type'),
        groupKey: 'item_type',
        limit: '5',
        label: 'Departemen Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('supplier'),
        groupKey: 'supplier',
        limit: '5',
        label: 'Supplier Terjual Terbanyak'),
  ];

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) => Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: colorScheme.outline, width: 1)),
            child: _panels[index]),
        itemCount: _panels.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: 10,
        ),
      ),
    );
  }
}
