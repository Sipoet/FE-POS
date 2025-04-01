import 'package:fe_pos/model/role_work_schedule.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/time_form_field.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/role.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import "package:collection/collection.dart";

class RoleFormPage extends StatefulWidget {
  final Role role;
  const RoleFormPage({super.key, required this.role});

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage>
    with
        AutomaticKeepAliveClientMixin,
        HistoryPopup,
        LoadingPopup,
        DefaultResponse {
  late final Flash flash;
  final codeInputWidget = TextEditingController();
  final focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  late final Server server;
  List<GroupWorkSchedule> groupWorkSchedules = [];
  Role get role => widget.role;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    super.initState();
    if (role.id != null) {
      Future.delayed(Duration.zero, fetchRole);
    }
  }

  void fetchRole() {
    showLoadingPopup();

    server.get('roles/${role.id}', queryParam: {
      'include': 'column_authorizes,access_authorizes,role_work_schedules'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          Role.fromJson(response.data['data'],
              model: role, included: response.data['included']);
          groupWorkSchedules = [];
          groupBy<RoleWorkSchedule, GroupWorkSchedule>(
            role.roleWorkSchedules,
            (roleWorkSchedule) => GroupWorkSchedule(
                groupName: roleWorkSchedule.groupName,
                beginActiveAt: roleWorkSchedule.beginActiveAt,
                endActiveAt: roleWorkSchedule.endActiveAt,
                level: roleWorkSchedule.level),
          ).forEach((groupWorkSchedule, value) {
            groupWorkSchedule.details = value
                .map<DetailSchedule>((roleWorkSchedule) => DetailSchedule(
                    dayOfWeek: roleWorkSchedule.dayOfWeek,
                    shift: roleWorkSchedule.shift,
                    beginWork: roleWorkSchedule.beginWork,
                    isFlexible: roleWorkSchedule.isFlexible,
                    endWork: roleWorkSchedule.endWork))
                .toList()
              ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
            groupWorkSchedules.add(groupWorkSchedule);
          });
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() {
      hideLoadingPopup();
      focusNode.requestFocus();
    });
  }

  List<RoleWorkSchedule> _decodeGroupSchedule() {
    List<RoleWorkSchedule> result = [];
    for (final groupWorkSchedule in groupWorkSchedules) {
      for (final detailSchedule in groupWorkSchedule.details) {
        result.add(RoleWorkSchedule(
          id: detailSchedule.id,
          beginActiveAt: groupWorkSchedule.beginActiveAt,
          endActiveAt: groupWorkSchedule.endActiveAt,
          shift: detailSchedule.shift,
          beginWork: detailSchedule.beginWork,
          endWork: detailSchedule.endWork,
          level: groupWorkSchedule.level,
          isFlexible: detailSchedule.isFlexible,
          dayOfWeek: detailSchedule.dayOfWeek,
          groupName: groupWorkSchedule.groupName,
        ));
      }
    }
    return result;
  }

  void _submit() async {
    role.roleWorkSchedules = _decodeGroupSchedule();
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
          },
          'role_work_schedules': {
            'data': role.roleWorkSchedules
                .map<Map>((roleWorkSchedule) => {
                      'id': roleWorkSchedule.id,
                      'type': 'role_work_schedule',
                      'attributes': roleWorkSchedule.toJson()
                    })
                .toList()
          },
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
          Role.fromJson(data, included: response.data['included'], model: role);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit role ${role.name}');
        });
        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
    });
  }

  List<RoleWorkSchedule> workScheduleByGroup(
      GroupWorkSchedule groupWorkSchedule) {
    return role.roleWorkSchedules
        .where((line) => line.groupName == groupWorkSchedule.groupName)
        .toList();
  }

  List<Widget> workScheduleForms() {
    List<Widget> formWidgets = [];
    for (final groupWorkSchedule in groupWorkSchedules) {
      formWidgets.addAll([
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 600,
          child: TextFormField(
            initialValue: groupWorkSchedule.groupName,
            decoration: const InputDecoration(
                labelText: 'Group Name',
                labelStyle: labelStyle,
                border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'harus diisi';
              }
              return null;
            },
            onSaved: (value) {
              groupWorkSchedule.groupName = value ?? '';
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 600,
          child: TextFormField(
            initialValue: groupWorkSchedule.level.toString(),
            decoration: const InputDecoration(
                labelText: 'Level',
                labelStyle: labelStyle,
                border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'harus diisi';
              }
              if (int.tryParse(value) == null) {
                return 'harus angka';
              }
              return null;
            },
            keyboardType: TextInputType.number,
            onSaved: (value) {
              groupWorkSchedule.level = int.tryParse(value ?? '') ?? 0;
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 600,
          child: DateRangeFormField(
            datePickerOnly: true,
            initialDateRange: DateTimeRange(
                start: groupWorkSchedule.beginActiveAt,
                end: groupWorkSchedule.endActiveAt),
            label: const Text('Jarak Aktif'),
            onChanged: (value) {
              if (value == null) {
                return value;
              }
              groupWorkSchedule.beginActiveAt =
                  Date.parsingDateTime(value.start);
              groupWorkSchedule.endActiveAt = Date.parsingDateTime(value.end);
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              dataRowMinHeight: 60,
              dataRowMaxHeight: 100,
              showBottomBorder: true,
              columns: [
                const DataColumn(
                    label: Text(
                  'Hari',
                  style: labelStyle,
                )),
                const DataColumn(
                    label: Text(
                  'Shift',
                  style: labelStyle,
                )),
                const DataColumn(
                    label: Text(
                  'Mulai',
                  style: labelStyle,
                )),
                const DataColumn(
                    label: Text(
                  'Akhir',
                  style: labelStyle,
                )),
                DataColumn(
                    label: Row(
                  children: [
                    Checkbox(
                        value: groupWorkSchedule.isFlexible,
                        onChanged: (isFlexible) {
                          setState(() {
                            groupWorkSchedule.isFlexible = isFlexible ?? false;
                            for (final detail in groupWorkSchedule.details) {
                              detail.isFlexible = isFlexible ?? false;
                            }
                          });
                        }),
                    Text(
                      'Fleksibel?',
                      style: labelStyle,
                    ),
                  ],
                )),
                DataColumn(
                    label: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      groupWorkSchedule.details.clear();
                    });
                  },
                  child: const Text(
                    'hapus semua',
                    style: labelStyle,
                  ),
                )),
              ],
              rows: groupWorkSchedule.details
                  .map<DataRow>((detailSchedule) => DataRow(cells: [
                        DataCell(DropdownMenu<int>(
                          initialSelection: detailSchedule.dayOfWeek,
                          onSelected: ((value) => setState(() {
                                detailSchedule.dayOfWeek = value ?? 0;
                              })),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: 1, label: 'Senin'),
                            DropdownMenuEntry(value: 2, label: 'Selasa'),
                            DropdownMenuEntry(value: 3, label: 'Rabu'),
                            DropdownMenuEntry(value: 4, label: 'Kamis'),
                            DropdownMenuEntry(value: 5, label: 'Jumat'),
                            DropdownMenuEntry(value: 6, label: 'Sabtu'),
                            DropdownMenuEntry(value: 7, label: 'Minggu'),
                          ],
                        )),
                        DataCell(TextFormField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          initialValue: detailSchedule.shift.toString(),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSaved: (value) =>
                              detailSchedule.shift = int.parse(value ?? '1'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'harus diisi';
                            }
                            if (int.tryParse(value) == null) {
                              return 'tidak valid';
                            }
                            if (int.parse(value) <= 0) {
                              return 'harus lebih besar dari 0';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              detailSchedule.shift = int.tryParse(value) ?? 0,
                        )),
                        DataCell(
                          TimeFormField(
                            initialValue: detailSchedule.beginWork,
                            onSaved: (value) => detailSchedule.beginWork =
                                value ?? detailSchedule.beginWork,
                            helpText: 'Mulai Kerja',
                            validator: (value) {
                              if (value == null) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        DataCell(
                          TimeFormField(
                            initialValue: detailSchedule.endWork,
                            onSaved: (value) => detailSchedule.endWork =
                                value ?? detailSchedule.endWork,
                            helpText: 'Akhir Kerja',
                            validator: (value) {
                              if (value == null) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        DataCell(Checkbox(
                            value: detailSchedule.isFlexible,
                            onChanged: (value) => setState(() {
                                  detailSchedule.isFlexible = value ?? false;
                                }))),
                        DataCell(Row(
                          children: [
                            Visibility(
                              visible: detailSchedule.id != null,
                              child: IconButton(
                                onPressed: () {
                                  fetchHistoryByRecord(
                                      'RoleWorkSchedule', detailSchedule.id);
                                },
                                icon: const Icon(Icons.history),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  groupWorkSchedule.details
                                      .remove(detailSchedule);
                                });
                              },
                              child: const Text('Hapus'),
                            ),
                          ],
                        )),
                      ]))
                  .toList()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: ElevatedButton(
              onPressed: () => setState(() {
                    groupWorkSchedule.details.add(DetailSchedule(
                        beginWork: const TimeOfDay(hour: 8, minute: 0),
                        endWork: const TimeOfDay(hour: 22, minute: 0)));
                  }),
              child: const Text('Tambah')),
        ),
      ]);
    }
    return formWidgets;
  }

  void _addNewGroupSchedule() {
    final newLength = groupWorkSchedules.length + 1;

    final groupName = "Jadwal Baru ${newLength.toString()}";
    setState(() {
      var groupWorkSchedule = GroupWorkSchedule(
          groupName: groupName,
          beginActiveAt: Date.today(),
          endActiveAt: Date.today(),
          details: [
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 1),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 2),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 3),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 4),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 5),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 6),
            DetailSchedule(
                beginWork: const TimeOfDay(hour: 8, minute: 0),
                endWork: const TimeOfDay(hour: 22, minute: 0),
                shift: 1,
                dayOfWeek: 7),
          ],
          level: 1);

      groupWorkSchedules.add(groupWorkSchedule);
      role.roleWorkSchedules.addAll([
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 1),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 2),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 3),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 4),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 5),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 6),
        RoleWorkSchedule(
            beginActiveAt: Date.today(),
            endActiveAt: Date.today(),
            groupName: groupName,
            beginWork: const TimeOfDay(hour: 8, minute: 0),
            endWork: const TimeOfDay(hour: 22, minute: 0),
            dayOfWeek: 7),
      ]);
    });
  }

  static const labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    super.build(context);
    codeInputWidget.text = role.name;
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    double height = size.height - padding.top - padding.bottom - 230;
    height = height > 600 ? 600 : height;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                            SizedBox(
                              width: 600,
                              child: TextFormField(
                                focusNode: focusNode,
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
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              'Akses Menu',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            DataTable(
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 250,
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
                                    .map<DataRow>((accessAuthorize) =>
                                        DataRow(cells: [
                                          DataCell(SizedBox(
                                            width: 350,
                                            child: AsyncDropdown<String>(
                                                onChanged: (value) =>
                                                    setState(() {
                                                      accessAuthorize
                                                              .controller =
                                                          value ?? '';
                                                    }),
                                                selected:
                                                    accessAuthorize.controller,
                                                textOnSearch: (value) => value,
                                                converter: (json,
                                                        {List included =
                                                            const []}) =>
                                                    json['id'].toString(),
                                                path: 'roles/controller_names'),
                                          )),
                                          DataCell(SizedBox(
                                            width: 350,
                                            child:
                                                AsyncDropdownMultiple<String>(
                                              onChanged: (value) =>
                                                  accessAuthorize.action =
                                                      value,
                                              selecteds: accessAuthorize.action,
                                              textOnSearch: (value) => value,
                                              converter: (json,
                                                      {List included =
                                                          const []}) =>
                                                  json['id'].toString(),
                                              request: (
                                                  {int page = 1,
                                                  int limit = 20,
                                                  String searchText = '',
                                                  required CancelToken
                                                      cancelToken}) {
                                                return server.get(
                                                    'roles/action_names',
                                                    queryParam: {
                                                      'search_text': searchText,
                                                      'controller_name':
                                                          accessAuthorize
                                                              .controller,
                                                      'page[page]':
                                                          page.toString(),
                                                    },
                                                    cancelToken: cancelToken);
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
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: ElevatedButton(
                                  onPressed: () => setState(() {
                                        role.accessAuthorizes.add(
                                            AccessAuthorize(
                                                controller: '', action: []));
                                      }),
                                  child: const Text('Tambah')),
                            ),
                            const Text(
                              "Akses Kolom Tabel",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 250,
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
                                    .map<DataRow>((columnAuthorize) =>
                                        DataRow(cells: [
                                          DataCell(SizedBox(
                                            width: 350,
                                            child: AsyncDropdown<String>(
                                                textOnSearch: (value) => value,
                                                onChanged: (value) =>
                                                    columnAuthorize.table =
                                                        value ?? '',
                                                selected: columnAuthorize.table,
                                                converter: (json,
                                                        {List included =
                                                            const []}) =>
                                                    json['id'].toString(),
                                                path: 'roles/table_names'),
                                          )),
                                          DataCell(SizedBox(
                                            width: 350,
                                            child: AsyncDropdownMultiple<
                                                    String>(
                                                onChanged: (value) =>
                                                    setState(() {
                                                      columnAuthorize.column =
                                                          value;
                                                    }),
                                                selecteds:
                                                    columnAuthorize.column,
                                                textOnSearch: (value) => value,
                                                converter: (json,
                                                        {List included =
                                                            const []}) =>
                                                    json['id'].toString(),
                                                request: (
                                                    {int page = 1,
                                                    int limit = 20,
                                                    String searchText = '',
                                                    required CancelToken
                                                        cancelToken}) {
                                                  return server.get(
                                                      'roles/column_names',
                                                      queryParam: {
                                                        'search_text':
                                                            searchText,
                                                        'table_name':
                                                            columnAuthorize
                                                                .table,
                                                        'page[page]':
                                                            page.toString(),
                                                        'page[limit]': '50',
                                                      },
                                                      cancelToken: cancelToken);
                                                }),
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
                                        role.columnAuthorizes.add(
                                            ColumnAuthorize(
                                                table: '', column: []));
                                      }),
                                  child: const Text('Tambah')),
                            ),
                            const Text(
                              "Jadwal Kerja",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                                onPressed: () => _addNewGroupSchedule(),
                                child: const Text('Tambah Group Jadwal')),
                          ] +
                          workScheduleForms()),
                ),
              ),
            ),
          ),
          Divider(
            thickness: 3,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    flash.show(const Text('Loading'), ToastificationType.info);
                    _submit();
                  }
                },
                child: const Text('submit')),
          ),
        ],
      ),
    );
  }
}

class GroupWorkSchedule {
  String groupName;
  Date beginActiveAt;
  Date endActiveAt;
  int level;
  bool isFlexible;
  List<DetailSchedule> details = [];
  GroupWorkSchedule(
      {this.level = 1,
      this.groupName = '',
      List<DetailSchedule>? details,
      this.isFlexible = false,
      Date? beginActiveAt,
      Date? endActiveAt})
      : beginActiveAt = beginActiveAt ?? Date.today(),
        endActiveAt = endActiveAt ?? Date.today(),
        details = details ?? <DetailSchedule>[];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupWorkSchedule &&
          runtimeType == other.runtimeType &&
          groupName == other.groupName;

  @override
  int get hashCode => groupName.hashCode;
}

class DetailSchedule {
  int? id;
  int dayOfWeek;
  int shift;
  TimeOfDay beginWork;
  TimeOfDay endWork;
  bool isFlexible;
  DetailSchedule(
      {this.dayOfWeek = 1,
      this.shift = 1,
      this.id,
      this.isFlexible = false,
      this.beginWork = const TimeOfDay(hour: 8, minute: 0),
      this.endWork = const TimeOfDay(hour: 22, minute: 0)});
}
