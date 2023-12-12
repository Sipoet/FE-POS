import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:data_table_2/data_table_2.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final DiscountDatatableSource _source = DiscountDatatableSource();

  @override
  Widget build(BuildContext context) {
    // var sessionState = context.watch<SessionState>();
    // var server = sessionState.server;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount'),
        actions: [
          ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text('refresh all promotion'))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Center(
              child: Text('Discount page'),
            ),
            PaginatedDataTable2(columns: [], source: _source)
          ],
        ),
      ),
    );
  }
}

class DiscountDatatableSource extends DataTableSource {
  late List<List<Comparable<Object>>> sortedData;
  void setData(List<List<Comparable<Object>>> rawData, int sortColumn,
      bool sortAscending) {
    sortedData = rawData.toList();
    sortData(sortColumn, sortAscending);
  }

  void sortData(int sortColumn, bool sortAscending) {
    sortedData.sort((List<Comparable<Object>> a, List<Comparable<Object>> b) {
      final Comparable<Object> cellA = a[sortColumn];
      final Comparable<Object> cellB = b[sortColumn];
      return cellA.compareTo(cellB) * (sortAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  static DataCell _decorateCell(Object cell) {
    if (cell is double || cell is int) {
      String val = _formatNumber(cell);
      return DataCell(
          Align(alignment: Alignment.centerRight, child: SelectableText(val)));
    } else {
      return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _formatNumber(number) {
    var um = number.toString().split('.');
    int strLength = um[0].length;
    List components = [];
    while (strLength >= 3) {
      components.add(um[0].substring(strLength - 3, strLength));
      components.add(',');
      strLength -= 3;
    }
    if (strLength > 0) {
      components.add(um[0].substring(0, strLength));
    } else {
      components.removeAt(components.length - 1);
    }
    components = components.reversed.toList();
    if (um.length == 2) components.add(".${um[1]}");
    return components.join();
  }

  @override
  DataRow? getRow(int index) {
    return DataRow.byIndex(
      index: index,
      cells: sortedData[index]
          .map<DataCell>((cell) => _decorateCell(cell))
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
