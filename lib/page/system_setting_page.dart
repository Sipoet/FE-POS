import 'package:fe_pos/model/system_setting.dart';
import 'package:fe_pos/page/system_setting_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class SystemSettingPage extends StatefulWidget {
  const SystemSettingPage({super.key});

  @override
  State<SystemSettingPage> createState() => _SystemSettingPageState();
}

class _SystemSettingPageState extends State<SystemSettingPage>
    with DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;

  final cancelToken = CancelToken();
  late Flash flash;
  List<SystemSetting> records = [];
  late final List<TableColumn> columns;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();

    columns = setting.tableColumn('setting');
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  void _openEditForm(SystemSetting record) {
    final tabManager = context.read<TabManager>();
    tabManager.addTab(
      'Edit System Setting ${record.key}',
      SystemSettingFormPage(systemSetting: record),
    );
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<SystemSetting>> fetchSystemSettings(
    QueryRequest request,
  ) {
    return SystemSettingClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<SystemSetting>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<SystemSetting>(
                renderAction: (model) => Row(
                  children: [
                    IconButton(
                      onPressed: () => _openEditForm(model),
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 0,
                fetchData: fetchSystemSettings,
                columns: columns,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
