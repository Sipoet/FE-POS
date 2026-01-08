import 'package:fe_pos/model/user.dart';
import 'package:fe_pos/page/user_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  final _menuController = MenuController();
  late final Setting setting;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('user');
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<User>> fetchUsers(QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include.add('role');
    return UserClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<User>(
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
    User user = User(
      username: '',
      role: Role(name: ''),
    );

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'New User',
        UserFormPage(key: ObjectKey(user), user: user),
      );
    });
  }

  void editForm(User user) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit User ${user.username}',
        UserFormPage(key: ObjectKey(user), user: user),
      );
    });
  }

  void destroyRecord(User user) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${user.username}?',
      onSubmit: () {
        server
            .delete('/users/${user.username}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description: 'Sukses Hapus user ${user.username}',
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

  void _unlockAccess(User user) {
    server
        .post('/users/${user.username}/unlock_access')
        .then(
          (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses unlock',
                description: 'Sukses unlock ${user.username}',
              );
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
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
              enums: const {'status': UserStatus.values},
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
                      decoration: const InputDecoration(
                        hintText: 'Search Text',
                      ),
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
                          child: const Text('Tambah User'),
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
              width: 825,
              child: CustomAsyncDataTable<User>(
                renderAction: (user) => Row(
                  spacing: 10,
                  children: [
                    if (setting.isAuthorize('user', 'update'))
                      IconButton(
                        onPressed: () {
                          editForm(user);
                        },
                        tooltip: 'Edit User',
                        icon: const Icon(Icons.edit),
                      ),
                    if (setting.isAuthorize('user', 'unlock_access'))
                      IconButton(
                        tooltip: 'unlock Akses User',
                        icon: const Icon(Icons.lock_open),
                        onPressed: () => _unlockAccess(user),
                      ),
                    if (setting.isAuthorize('user', 'destroy'))
                      IconButton(
                        onPressed: () {
                          destroyRecord(user);
                        },
                        tooltip: 'Hapus User',
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 1,
                columns: columns,
                fetchData: fetchUsers,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
