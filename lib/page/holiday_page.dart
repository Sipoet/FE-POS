import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/holiday.dart';
import 'package:fe_pos/page/holiday_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<Holiday> _source;
  late final Server server;
  final _menuController = MenuController();
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<Holiday>(
        columns: setting.tableColumn('holiday'), fetchData: fetchHolidays);
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshDataFromFirstPage();
  }

  Future<ResponseResult<Holiday>> fetchHolidays(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = false}) {
    String orderKey = sortColumn?.name ?? 'date';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });

    return server.get('holidays', queryParam: param, cancelToken: cancelToken).then(
        (response) {
      if (response.statusCode != 200) {
        throw 'error: ${response.data.toString()}';
      }
      try {
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<Holiday>((json) => Holiday.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<Holiday>(models: models, totalRows: totalRows);
      } catch (e, trace) {
        flash.showBanner(
            title: e.toString(),
            description: trace.toString(),
            messageType: ToastificationType.error);
        return Future(() => ResponseResult<Holiday>(models: []));
      }
    },
        onError: (error, stackTrace) =>
            defaultErrorResponse(error: error, valueWhenError: []));
  }

  void addForm() {
    Holiday holiday = Holiday();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Tambah Liburan',
          HolidayFormPage(key: ObjectKey(holiday), holiday: holiday));
    });
  }

  void editForm(Holiday holiday) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit Liburan ${holiday.id}',
          HolidayFormPage(key: ObjectKey(holiday), holiday: holiday));
    });
  }

  void destroyRecord(Holiday holiday) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${holiday.id}?',
        onSubmit: () {
          server.delete('/holidays/${holiday.id}').then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description: 'Sukses Hapus Liburan ${holiday.id}');
              refreshTable();
            }
          }, onError: (error) {
            defaultErrorResponse(error: error);
          });
        });
  }

  void searchChanged(value) {
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = ((holiday, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(holiday);
              },
              tooltip: 'Edit Holiday',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(holiday);
              },
              tooltip: 'Hapus Holiday',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              enums: {'religion': Religion.values},
              onSubmit: (filter) {
                _filter = filter;
                refreshTable();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchText = '';
                      });
                      refreshTable();
                    },
                    tooltip: 'Reset Table',
                    icon: const Icon(Icons.refresh),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      decoration:
                          const InputDecoration(hintText: 'Search Text'),
                      onChanged: searchChanged,
                      onSubmitted: searchChanged,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                        controller: _menuController,
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Tambah Libur Karyawan'),
                            onPressed: () {
                              _menuController.close();
                              addForm();
                            },
                          ),
                        ],
                        child: const Icon(Icons.table_rows_rounded)),
                  )
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              width: 900,
              child: CustomAsyncDataTable(
                controller: _source,
                fixedLeftColumns: 2,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
