import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/role.dart';
import 'package:provider/provider.dart';

class RoleFormPage extends StatefulWidget {
  final Role role;
  const RoleFormPage({super.key, required this.role});

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage>
    with AutomaticKeepAliveClientMixin {
  late final Flash flash;
  final codeInputWidget = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  Role get role => widget.role;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
    if (role.id != null) {
      fetchRole();
    }
  }

  void fetchRole() {
    final server = context.read<Server>();
    server.get('roles/${role.id}', queryParam: {
      'include': 'column_authorizes,access_authorizes'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          Role.fromJson(response.data['data'],
              model: role, included: response.data['included']);
        });
      }
    }, onError: (error) {
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'role',
        'id': role.id,
        'attributes': role.toJson(),
        'relationships': {
          'column_authorizes': {
            'data': role.columnAuthorizes
                .map<Map>((columnAuthorize) => {
                      'id': columnAuthorize.id,
                      'type': 'column_authorize',
                      'attributes': columnAuthorize.toJson()
                    })
                .toList()
          },
          'access_authorizes': {
            'data': role.accessAuthorizes
                .map<Map>((accessAuthorize) => {
                      'id': accessAuthorize.id,
                      'type': 'access_authorize',
                      'attributes': accessAuthorize.toJson()
                    })
                .toList()
          }
        }
      }
    };
    Future request;
    if (role.id == null) {
      request = server.post('roles', body: body);
    } else {
      request = server.put('roles/${role.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          role.id = int.tryParse(data['id']);
          role.name = data['attributes']['name'];
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit role ${role.name}');
        });
        fetchRole();
        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    codeInputWidget.text = role.name;
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Center(
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(600)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Nama',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      role.name = newValue.toString();
                    },
                    onChanged: (newValue) {
                      role.name = newValue.toString();
                    },
                    controller: codeInputWidget,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Akses Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 150,
                        showBottomBorder: true,
                        columns: [
                          const DataColumn(
                              label: Text(
                            'Controller Name',
                            style: labelStyle,
                          )),
                          const DataColumn(
                              label: Text(
                            'Action Name',
                            style: labelStyle,
                          )),
                          DataColumn(
                              label: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                role.accessAuthorizes.clear();
                              });
                            },
                            child: const Text(
                              'hapus semua',
                              style: labelStyle,
                            ),
                          )),
                        ],
                        rows: role.accessAuthorizes
                            .map<DataRow>((accessAuthorize) => DataRow(cells: [
                                  DataCell(SizedBox(
                                    width: 250,
                                    child: AsyncDropdown(
                                        onChanged: (value) => setState(() {
                                              accessAuthorize.controller =
                                                  value?.value ?? '';
                                            }),
                                        selected: accessAuthorize
                                                .controller.isEmpty
                                            ? null
                                            : DropdownResult(
                                                value:
                                                    accessAuthorize.controller,
                                                text:
                                                    accessAuthorize.controller),
                                        path: 'roles/controller_names'),
                                  )),
                                  DataCell(SizedBox(
                                    width: 250,
                                    child: AsyncDropdownMultiple(
                                      multiple: true,
                                      onChanged: (value) => accessAuthorize
                                          .action = value
                                              ?.map<String>(
                                                  (e) => e.getValueAsString())
                                              .toList() ??
                                          [],
                                      selecteds: accessAuthorize.action
                                          .map<DropdownResult>((action) =>
                                              DropdownResult(
                                                  value: action, text: action))
                                          .toList(),
                                      request: (server, offset, searchText) {
                                        return server.get('roles/action_names',
                                            queryParam: {
                                              'search_text': searchText,
                                              'controller_name':
                                                  accessAuthorize.controller
                                            });
                                      },
                                    ),
                                  )),
                                  DataCell(ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        role.accessAuthorizes
                                            .remove(accessAuthorize);
                                      });
                                    },
                                    child: const Text('Hapus'),
                                  ))
                                ]))
                            .toList()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              role.accessAuthorizes.add(
                                  AccessAuthorize(controller: '', action: []));
                            }),
                        child: const Text('Tambah')),
                  ),
                  const Text(
                    "Akses Kolom Tabel",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 150,
                      showBottomBorder: true,
                      columns: [
                        const DataColumn(
                            label: Text(
                          'Tabel',
                          style: labelStyle,
                        )),
                        const DataColumn(
                            label: Text('Kolom', style: labelStyle)),
                        DataColumn(
                            label: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    role.columnAuthorizes.clear();
                                  });
                                },
                                child: const Text('Hapus Semua',
                                    style: labelStyle))),
                      ],
                      rows: role.columnAuthorizes
                          .map<DataRow>((columnAuthorize) => DataRow(cells: [
                                DataCell(SizedBox(
                                  width: 250,
                                  child: AsyncDropdown(
                                      onChanged: (value) => columnAuthorize
                                          .table = value?.value ?? '',
                                      selected: columnAuthorize.table.isEmpty
                                          ? null
                                          : DropdownResult(
                                              value: columnAuthorize.table,
                                              text: columnAuthorize.table),
                                      path: 'roles/table_names'),
                                )),
                                DataCell(SizedBox(
                                  width: 250,
                                  child: AsyncDropdownMultiple(
                                    multiple: true,
                                    onChanged: (value) => setState(() {
                                      columnAuthorize.column = value
                                              ?.map<String>((e) => e.toString())
                                              .toList() ??
                                          [];
                                    }),
                                    selecteds: columnAuthorize.column
                                        .map<DropdownResult>((column) =>
                                            DropdownResult(
                                                value: column, text: column))
                                        .toList(),
                                    request: (server, offset, searchText) =>
                                        server.get('roles/column_names',
                                            queryParam: {
                                          'search_text': searchText,
                                          'table_name': columnAuthorize.table
                                        }),
                                  ),
                                )),
                                DataCell(ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      role.columnAuthorizes
                                          .remove(columnAuthorize);
                                    });
                                  },
                                  child: const Text('Hapus'),
                                )),
                              ]))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              role.columnAuthorizes
                                  .add(ColumnAuthorize(table: '', column: []));
                            }),
                        child: const Text('Tambah')),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            flash.show(const Text('Loading'), MessageType.info);
                            _submit();
                          }
                        },
                        child: const Text('submit')),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
