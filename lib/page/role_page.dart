import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/role.dart';
import 'package:fe_pos/page/role_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<Role> _source;
  late final Server server;

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
    _source = CustomAsyncDataTableSource<Role>(
        columns: setting.tableColumn('role'), fetchData: fetchRoles);
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

  Future<ResponseResult<Role>> fetchRoles(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.name ?? 'name';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('roles', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<Role>((json) => Role.fromJson(json))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<Role>(models: models, totalRows: totalRows);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => ResponseResult<Role>(models: []));
    }
  }

  void addForm() {
    Role role = Role(name: '', columnAuthorizes: [], accessAuthorizes: []);

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'New Role', RoleFormPage(key: ObjectKey(role), role: role));
    });
  }

  void editForm(Role role) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit Role ${role.name}',
          RoleFormPage(key: ObjectKey(role), role: role));
    });
  }

  void destroyRecord(Role role) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${role.name}?',
        onSubmit: () {
          server.delete('/roles/${role.id}').then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description: 'Sukses Hapus role ${role.name}');
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
    _source.actionButtons = ((role, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(role);
              },
              tooltip: 'Edit Role',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(role);
              },
              tooltip: 'Hapus Role',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
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
                    child: SubmenuButton(menuChildren: [
                      MenuItemButton(
                        child: const Text('Tambah Role'),
                        onPressed: () => addForm(),
                      ),
                    ], child: const Icon(Icons.table_rows_rounded)),
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
