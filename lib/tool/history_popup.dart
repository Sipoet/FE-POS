import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/activity_log.dart';
import 'package:fe_pos/model/server.dart';
import 'package:intl/intl.dart';

mixin HistoryPopup<T extends StatefulWidget> on State<T> {
  final _source = HistorySource();

  void _showLoadingPopup() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer,
              ),
            ),
          );
        });
  }

  void _hideLoadingPopup() {
    Navigator.pop(context);
  }

  void fetchHistoryByRecord(
    String itemType,
    int? itemId,
  ) {
    _showLoadingPopup();

    final server = context.read<Server>();
    server.get('activity_logs/by_item', queryParam: {
      'item_type': itemType,
      'item_id': itemId.toString(),
    }).then((response) {
      if (response.statusCode == 200) {
        final json = response.data;
        setState(() {
          _source.setData(json['data']
              .map<ActivityLog>((lineJson) => ActivityLog.fromJson(lineJson,
                  included: json['included'] ?? []))
              .toList());
        });
        _hideLoadingPopup();
        showHistoryPopup();
      }
    }, onError: (error) {
      _hideLoadingPopup();
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  void fetchHistoryByUser(
    int userId,
  ) {
    _showLoadingPopup();

    final server = context.read<Server>();
    server.get('activity_logs/by_user', queryParam: {
      'user_id': userId.toString(),
    }).then((response) {
      if (response.statusCode == 200) {
        final json = response.data;
        setState(() {
          _source.setData(json['data']
              .map<ActivityLog>((lineJson) => ActivityLog.fromJson(lineJson,
                  included: json['included'] ?? []))
              .toList());
        });
        _hideLoadingPopup();
        showHistoryPopup();
      }
    }, onError: (error) {
      _hideLoadingPopup();
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  int _sortColumnIndex = 0;

  void showHistoryPopup() {
    final colorScheme = Theme.of(context).colorScheme;
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Container(
                    decoration: BoxDecoration(color: colorScheme.surface),
                    padding: const EdgeInsets.all(10),
                    child: PaginatedDataTable(
                      header: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      sortAscending: _source.isAscending,
                      sortColumnIndex: _sortColumnIndex,
                      rowsPerPage: 5,
                      dataRowMinHeight: 25,
                      dataRowMaxHeight: 120,
                      availableRowsPerPage: const [5, 10, 20, 50, 100],
                      columns: [
                        DataColumn(
                          label: const Text(
                            'Tanggal/Status',
                            style: labelStyle,
                          ),
                          onSort: (columnIndex, ascending) {
                            setStateDialog(() {
                              _source.sortData('created_at', ascending);
                              _sortColumnIndex = 0;
                            });
                          },
                        ),
                        DataColumn(
                          label: const Text('Pelaku', style: labelStyle),
                          onSort: (columnIndex, ascending) {
                            setStateDialog(() {
                              _source.sortData('actor', ascending);
                              _sortColumnIndex = 1;
                            });
                          },
                        ),
                        const DataColumn(
                          label: Text('Aksi', style: labelStyle),
                        ),
                        const DataColumn(
                          label: Text('Keterangan', style: labelStyle),
                        ),
                      ],
                      source: _source,
                    ),
                  ),
                ),
              ),
            );
          });
        });
  }
}

class HistorySource extends DataTableSource {
  late List<ActivityLog> sortedData = [];
  String sortColumn = 'created_at';
  bool isAscending = false;

  void updateData(index, ActivityLog model) {
    sortedData[index] = model;
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  void setData(List<ActivityLog> rawData) {
    sortedData = rawData;
    sortData(sortColumn, isAscending);
  }

  void sortData(String sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    sortedData.sort((ActivityLog a, ActivityLog b) {
      var cellA = a.toMap()[sortColumn] ?? '';
      var cellB = b.toMap()[sortColumn] ?? '';
      if (cellA is TimeOfDay) {
        cellA = cellA.toString();
        cellB = cellB.toString();
      }
      return cellA.compareTo(cellB) * (isAscending ? 1 : -1);
    });
    notifyListeners();
  }

  String dateTimeLocalFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date.toLocal());
  }

  @override
  int get rowCount => sortedData.length;

  @override
  DataRow? getRow(int index) {
    ActivityLog model = sortedData[index];
    return DataRow.byIndex(index: index, cells: [
      DataCell(
        Text(dateTimeLocalFormat(model.createdAt ?? DateTime(0))),
      ),
      DataCell(
        Text(model.actor),
      ),
      DataCell(Text("${model.event} ${model.itemType}")),
      DataCell(
        Tooltip(
            message: model.description,
            triggerMode: TooltipTriggerMode.longPress,
            child: SelectableText(model.description)),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
