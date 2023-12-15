import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final DiscountDatatableSource _source = DiscountDatatableSource();
  late final SessionState _sessionState;
  late final List<String> _columnOrder;
  List<DataColumn2> _columns = [];
  double _tableWidth = 50.0;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  bool _isDisplayTable = false;
  String _searchText = '';
  @override
  void initState() {
    _sessionState = context.read<SessionState>();
    refreshTable();
    super.initState();
  }

  Future<void> _fetchTableColumn() async {
    var server = _sessionState.server;
    var response = await server
        .get('discounts/columns', queryParam: {'search_text': _searchText});
    if (response.statusCode != 200) {
      return;
    }
    Map responseBody = jsonDecode(response.body);
    var data = responseBody['data'] ?? {'column_names': [], 'column_order': []};
    _columnOrder =
        data['column_order'].map<String>((e) => e.toString()).toList();
    _source.setKeys(_columnOrder);
    _columns = [];
    setState(() {
      _tableWidth = 50.0;
      data['column_names'].forEach((columnName) {
        _tableWidth += 215.0;
        _columns.add(DataColumn2(
          fixedWidth: 215.0,
          onSort: ((columnIndex, ascending) {
            setState(() {
              _sortColumnIndex = columnIndex;
              _sortAscending = ascending;
            });
            _source.sortData(_sortColumnIndex, _sortAscending);
          }),
          label: Text(
            columnName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ));
      });
      _tableWidth += 150.0;
      _columns.add(const DataColumn2(
          label: Text(
            'Action',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          fixedWidth: 150.0));
    });
  }

  Future<void> refreshTable() async {
    if (_columns.isEmpty) {
      await _fetchTableColumn();
    } else {
      displayFlash(const Text("Sedang proses."),
          duration: const Duration(minutes: 5));
    }
    List discounts = await fetchDiscounts();
    hideFlash();
    // hideFlash();
    setState(() {
      var rawData = discounts.map<List<Comparable<Object>>>((row) {
        Map attributes = row['attributes'];
        return _columnOrder
            .map<Comparable<Object>>((key) => attributes[key] ?? '')
            .toList();
      }).toList();
      _source.setData(rawData, _sortColumnIndex, _sortAscending);
      _isDisplayTable = true;
    });
  }

  Future<List> fetchDiscounts() async {
    var server = _sessionState.server;
    var response =
        await server.get('discounts', queryParam: {'search_text': _searchText});
    try {
      if (response.statusCode != 200) {
        throw 'error: ${response.body.toString()}';
      }
      Map responseBody = jsonDecode(response.body);
      if (responseBody['data'] is List) {
        return responseBody['data'];
      } else {
        throw 'error: invalid data type ${response.body.toString()}';
      }
    } catch (e) {
      return [];
    }
  }

  void addForm() {}
  void editForm() {}
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    _source.editForm = editForm;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search Text'),
                    onChanged: (value) {
                      String container = _searchText;
                      setState(() {
                        if (value.length >= 3) {
                          _searchText = value;
                        } else {
                          _searchText = '';
                        }
                      });
                      if (container != _searchText) {
                        refreshTable();
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    refreshTable();
                  },
                  tooltip: 'Refresh Table',
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () {
                    addForm();
                  },
                  tooltip: 'Refresh Table',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (_isDisplayTable)
            Expanded(
              child: PaginatedDataTable2(
                columns: _columns,
                source: _source,
                minWidth: _tableWidth,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                fixedLeftColumns: 1,
                border: TableBorder.all(
                    width: 1, color: Colors.black45.withOpacity(0.3)),
                sortArrowAlwaysVisible: false,
                empty: const Text('Data tidak ditemukan'),
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blueAccent.withOpacity(0.2);
                }),
              ),
            ),
        ],
      ),
    );
  }

  void displayFlash(Widget content,
      {Duration duration = const Duration(seconds: 5)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 80,
            left: MediaQuery.of(context).size.width - 350,
            right: 50),
      ),
    );
  }

  void hideFlash() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

class DiscountDatatableSource extends DataTableSource {
  late List<List<Comparable<Object>>> sortedData;
  late List<String> keys;
  late Function editForm;
  void setData(List<List<Comparable<Object>>> rawData, int sortColumn,
      bool sortAscending) {
    sortedData = rawData.toList();
    sortData(sortColumn, sortAscending);
  }

  void setKeys(List<String> keys) {
    this.keys = keys;
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

  static DataCell _decorateCell(String key, Object cell) {
    if (['start_time', 'end_time'].contains(key)) {
      String val = _formatDate(cell);
      return DataCell(SelectableText(val));
    } else if (cell is double || cell is int) {
      String val = _formatNumber(cell);
      return DataCell(
          Align(alignment: Alignment.centerRight, child: SelectableText(val)));
    } else {
      return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _formatDate(cell) {
    if (cell == null) return '';
    DateTime date = DateTime.parse(cell.toString());
    var formated = DateFormat('d/M/y H:m');
    return formated.format(date.toLocal());
  }

  static String _formatNumber(number) {
    var formated = NumberFormat(",##0.##", "en_US");
    return formated.format(number);
  }

  @override
  DataRow? getRow(int index) {
    int indexCol = 0;
    return DataRow.byIndex(
      index: index,
      cells: sortedData[index]
              .map<DataCell>((value) => _decorateCell(keys[indexCol++], value))
              .toList() +
          [_actionButton(index)],
    );
  }

  DataCell _actionButton(index) {
    return DataCell(Row(
      children: [
        ElevatedButton.icon(
            onPressed: () {
              editForm(sortedData[index]);
            },
            icon: const Icon(Icons.edit),
            label: const Text('edit'))
      ],
    ));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
