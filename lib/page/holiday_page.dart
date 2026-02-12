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
  late final TableController _source;
  late final Server server;
  final _menuController = MenuController();

  final cancelToken = CancelToken();
  late Flash flash;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('holiday');
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
    _source.refreshTable();
  }

  Future<DataTableResponse<Holiday>> fetchHolidays(QueryRequest request) {
    request.filters = _filters;

    return HolidayClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Holiday>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void addForm() {
    Holiday holiday = Holiday();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Tambah Liburan',
        HolidayFormPage(key: ObjectKey(holiday), holiday: holiday),
      );
    });
  }

  void editForm(Holiday holiday) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Liburan ${holiday.id}',
        HolidayFormPage(key: ObjectKey(holiday), holiday: holiday),
      );
    });
  }

  void destroyRecord(Holiday holiday) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${holiday.id}?',
      onSubmit: () {
        server
            .delete('/holidays/${holiday.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description: 'Sukses Hapus Liburan ${holiday.id}',
                  );
                  refreshTable();
                }
              },
              onError: (error) {
                defaultErrorResponse(error: error);
              },
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: columns,
              enums: {'religion': Religion.values},
              onSubmit: (filter) {
                _filters = filter;
                refreshTable();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                      child: const Icon(Icons.table_rows_rounded),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<Holiday>(
                renderAction: (holiday) => Row(
                  spacing: 10,
                  children: [
                    IconButton(
                      onPressed: () {
                        editForm(holiday);
                      },
                      tooltip: 'Edit Holiday',
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        destroyRecord(holiday);
                      },
                      tooltip: 'Hapus Holiday',
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
                columns: columns,
                fetchData: fetchHolidays,
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
