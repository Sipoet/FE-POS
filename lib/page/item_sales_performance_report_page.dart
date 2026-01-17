import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:flutter/material.dart';

class ItemSalesPerformanceReportPage extends StatefulWidget {
  const ItemSalesPerformanceReportPage({super.key});

  @override
  State<ItemSalesPerformanceReportPage> createState() =>
      _ItemSalesPerformanceReportPageState();
}

class _ItemSalesPerformanceReportPageState
    extends State<ItemSalesPerformanceReportPage> {
  List<Widget> filterColumns = [];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateRangeFormField<Date>(
          label: Text('Jarak Periode'),
          rangeType: DateRangeType(),
        ),
        Row(
          children: [
            DropdownMenu(
              label: const Text('Filter Berdasarkan'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'item', label: 'Item'),
                DropdownMenuEntry(
                  value: 'item_type',
                  label: 'Jenis/ Departemen',
                ),
                DropdownMenuEntry(value: 'brand', label: 'Merek'),
                DropdownMenuEntry(value: 'supplier', label: 'Supplier'),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: IconButton(onPressed: addFilter, icon: Icon(Icons.add)),
            ),
          ],
        ),
        Column(children: filterColumns),
      ],
    );
  }

  void addFilter() {}
}
