import 'package:fe_pos/model/role_work_schedule.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/time_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/role.dart';
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
  late final Setting setting;
  List<GroupWorkSchedule> groupWorkSchedules = [];
  Role get role => widget.role;
  Map<String, Map<String, bool>> currentAction = {};
  Map<String, Map<String, bool>> currentColumn = {};
  List<ActionData> actionList = [];
  List<TableColumn> columnList = [];
  List<ControllerData> controllerList = [];
  ControllerData? currentController;
  String _searchText = '';
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Setting>();
    Future.delayed(Duration.zero, fetchControllers);
    super.initState();
    if (role.id != null) {
      Future.delayed(Duration.zero, fetchRole);
    }
  }

  void fetchControllers() {
    server
        .get(
          'roles/controller_names',
          queryParam: {'page': '1', 'limit': '9999'},
        )
        .then((response) {
          if (response.statusCode != 200) {
            return;
          }

          List data = response.data['data'];
          setState(() {
            controllerList = data
                .map<ControllerData>(
                  (datum) =>
                      ControllerData(label: datum['name'], value: datum['id']),
                )
                .toList();
          });
        });
  }

  void fetchColumnNames(ControllerData controllerData) {
    server
        .get(
          'roles/column_names',
          queryParam: {
            'table_name': controllerData.className,
            'page': '1',
            'limit': '9999',
          },
        )
        .then((response) {
          if (response.statusCode != 200) {
            return;
          }

          List data = response.data['data'];
          setState(() {
            columnList = data
                .map<TableColumn>(
                  (datum) => TableColumn(
                    clientWidth: 150,
                    humanizeName: datum['name'],
                    name: datum['id'],
                  ),
                )
                .toList();
          });
        });
  }

  void fetchControllerActions(ControllerData controllerData) {
    server
        .get(
          'roles/action_names',
          queryParam: {
            'controller_name': controllerData.value,
            'page': '1',
            'limit': '9999',
          },
        )
        .then((response) {
          if (response.statusCode != 200) {
            return;
          }

          List data = response.data['data'];
          setState(() {
            actionList = data
                .map<ActionData>(
                  (datum) =>
                      ActionData(label: datum['name'], value: datum['id']),
                )
                .toList();
          });
        });
  }

  void fetchRole() {
    showLoadingPopup();

    server
        .get(
          'roles/${role.id}',
          queryParam: {
            'include':
                'column_authorizes,access_authorizes,role_work_schedules',
          },
        )
        .then(
          (response) {
            if (response.statusCode != 200) {
              return;
            }
            setState(() {
              role.setFromJson(
                response.data['data'],
                included: response.data['included'],
              );
              groupWorkSchedules = [];
              groupBy<RoleWorkSchedule, GroupWorkSchedule>(
                role.roleWorkSchedules,
                (roleWorkSchedule) => GroupWorkSchedule(
                  groupName: roleWorkSchedule.groupName,
                  beginActiveAt: roleWorkSchedule.beginActiveAt,
                  endActiveAt: roleWorkSchedule.endActiveAt,
                  level: roleWorkSchedule.level,
                ),
              ).forEach((groupWorkSchedule, values) {
                groupBy<RoleWorkSchedule, DetailSchedule>(
                  values,
                  (value) => DetailSchedule(
                    shift: value.shift,
                    beginWork: value.beginWork,
                    endWork: value.endWork,
                    isFlexible: value.isFlexible,
                  ),
                ).forEach((detailSchedule, val) {
                  final dayOfWeeks = val.map((e) => e.dayOfWeek).toList();
                  detailSchedule.isMonday = dayOfWeeks.contains(1);
                  detailSchedule.isTuesday = dayOfWeeks.contains(2);
                  detailSchedule.isWednesday = dayOfWeeks.contains(3);
                  detailSchedule.isThursday = dayOfWeeks.contains(4);
                  detailSchedule.isFriday = dayOfWeeks.contains(5);
                  detailSchedule.isSaturday = dayOfWeeks.contains(6);
                  detailSchedule.isSunday = dayOfWeeks.contains(7);
                  groupWorkSchedule.details.add(detailSchedule);
                  groupWorkSchedule.details.sort(
                    (a, b) => a.shift.compareTo(b.shift),
                  );
                });

                groupWorkSchedules.add(groupWorkSchedule);

                for (AccessAuthorize accessAuthorize in role.accessAuthorizes) {
                  Map<String, bool> actionHash = {};
                  for (String action in accessAuthorize.actions) {
                    actionHash[action] = true;
                  }
                  currentAction[accessAuthorize.controller] = actionHash;
                }
                for (ColumnAuthorize columnAuthorize in role.columnAuthorizes) {
                  Map<String, bool> columnHash = {};
                  for (String column in columnAuthorize.columns) {
                    columnHash[column] = true;
                  }
                  currentColumn[columnAuthorize.table] = columnHash;
                }
              });
            });
          },
          onError: (error) {
            defaultErrorResponse(error: error);
          },
        )
        .whenComplete(() {
          hideLoadingPopup();
          focusNode.requestFocus();
        });
  }

  List<RoleWorkSchedule> _decodeGroupSchedule() {
    List<RoleWorkSchedule> result = [];
    for (final groupWorkSchedule in groupWorkSchedules) {
      for (final detailSchedule in groupWorkSchedule.details) {
        for (final dayOfWeek in detailSchedule.dayOfWeeks) {
          result.add(
            RoleWorkSchedule(
              beginActiveAt: groupWorkSchedule.beginActiveAt,
              endActiveAt: groupWorkSchedule.endActiveAt,
              shift: detailSchedule.shift,
              beginWork: detailSchedule.beginWork,
              endWork: detailSchedule.endWork,
              level: groupWorkSchedule.level,
              isFlexible: detailSchedule.isFlexible,
              dayOfWeek: dayOfWeek,
              groupName: groupWorkSchedule.groupName,
            ),
          );
        }
      }
    }
    return result;
  }

  List<ColumnAuthorize> _decodeColumnAuthorize() {
    List<ColumnAuthorize> result = [];
    for (final entry in currentColumn.entries) {
      List<String> columns = [];
      for (final columnEntry in entry.value.entries) {
        if (columnEntry.value) {
          columns.add(columnEntry.key);
        }
      }
      result.add(ColumnAuthorize(table: entry.key, columns: columns));
    }
    return result;
  }

  List<AccessAuthorize> _decodeAccessAuhorize() {
    List<AccessAuthorize> result = [];
    for (final entry in currentAction.entries) {
      List<String> actions = [];
      for (final actionEntry in entry.value.entries) {
        if (actionEntry.value) {
          actions.add(actionEntry.key);
        }
      }
      result.add(AccessAuthorize(controller: entry.key, actions: actions));
    }
    return result;
  }

  void _submit() async {
    role.roleWorkSchedules = _decodeGroupSchedule();
    role.columnAuthorizes = _decodeColumnAuthorize();
    role.accessAuthorizes = _decodeAccessAuhorize();
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'role',
        'id': role.id,
        'attributes': role.toJson(),
        'relationships': {
          'column_authorizes': {
            'data': role.columnAuthorizes
                .map<Map>(
                  (columnAuthorize) => {
                    'id': columnAuthorize.id,
                    'type': 'column_authorize',
                    'attributes': columnAuthorize.toJson(),
                  },
                )
                .toList(),
          },
          'access_authorizes': {
            'data': role.accessAuthorizes
                .map<Map>(
                  (accessAuthorize) => {
                    'id': accessAuthorize.id,
                    'type': 'access_authorize',
                    'attributes': accessAuthorize.toJson(),
                  },
                )
                .toList(),
          },
          'role_work_schedules': {
            'data': role.roleWorkSchedules
                .map<Map>(
                  (roleWorkSchedule) => {
                    'id': roleWorkSchedule.id,
                    'type': 'role_work_schedule',
                    'attributes': roleWorkSchedule.toJson(),
                  },
                )
                .toList(),
          },
        },
      },
    };
    Future request;
    if (role.id == null) {
      request = server.post('roles', body: body);
    } else {
      request = server.put('roles/${role.id}', body: body);
    }
    request.then(
      (response) {
        if ([200, 201].contains(response.statusCode)) {
          var data = response.data['data'];
          setState(() {
            role.setFromJson(data, included: response.data['included']);
            var tabManager = context.read<TabManager>();
            tabManager.changeTabHeader(widget, 'Edit role ${role.name}');
          });
          flash.show(
            const Text('Berhasil disimpan'),
            ToastificationType.success,
          );
        } else if (response.statusCode == 409) {
          var data = response.data;
          flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error,
          );
        }
      },
      onError: (error, stackTrace) {
        defaultErrorResponse(error: error);
      },
    );
  }

  List<RoleWorkSchedule> workScheduleByGroup(
    GroupWorkSchedule groupWorkSchedule,
  ) {
    return role.roleWorkSchedules
        .where((line) => line.groupName == groupWorkSchedule.groupName)
        .toList();
  }

  List<Widget> workScheduleForms() {
    List<Widget> formWidgets = [];
    for (final groupWorkSchedule in groupWorkSchedules) {
      formWidgets.addAll([
        const SizedBox(height: 10),
        SizedBox(
          width: 600,
          child: TextFormField(
            initialValue: groupWorkSchedule.groupName,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              labelStyle: labelStyle,
              border: OutlineInputBorder(),
            ),
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
        const SizedBox(height: 10),
        SizedBox(
          width: 600,
          child: TextFormField(
            initialValue: groupWorkSchedule.level.toString(),
            decoration: const InputDecoration(
              labelText: 'Level',
              labelStyle: labelStyle,
              border: OutlineInputBorder(),
            ),
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
        const SizedBox(height: 10),
        SizedBox(
          width: 600,
          child: DateRangeFormField(
            rangeType: DateRangeType(),
            initialValue: DateTimeRange(
              start: groupWorkSchedule.beginActiveAt,
              end: groupWorkSchedule.endActiveAt,
            ),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              groupWorkSchedule.beginActiveAt = Date.parsingDateTime(
                value.start,
              );
              groupWorkSchedule.endActiveAt = Date.parsingDateTime(value.end);
            },
            label: const Text('Jarak Aktif'),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 60,
            dataRowMaxHeight: 80,
            headingRowHeight: 100,
            showBottomBorder: true,
            columns: [
              const DataColumn(label: Text('Shift', style: labelStyle)),
              DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Mulai', style: labelStyle),
                    SizedBox(
                      width: 90,
                      child: TimeFormField(
                        onChanged: (time) {
                          setState(() {
                            for (final detail in groupWorkSchedule.details) {
                              detail.beginWork = time ?? detail.beginWork;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Akhir', style: labelStyle),
                    SizedBox(
                      width: 90,
                      child: TimeFormField(
                        onChanged: (time) {
                          setState(() {
                            for (final detail in groupWorkSchedule.details) {
                              detail.endWork = time ?? detail.endWork;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(label: Text('Senin', style: labelStyle)),
              DataColumn(label: Text('Selasa', style: labelStyle)),
              DataColumn(label: Text('Rabu', style: labelStyle)),
              DataColumn(label: Text('Kamis', style: labelStyle)),
              DataColumn(label: Text('Jumat', style: labelStyle)),
              DataColumn(label: Text('Sabtu', style: labelStyle)),
              DataColumn(label: Text('Minggu', style: labelStyle)),
              DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleksibel?', style: labelStyle),
                    Checkbox(
                      value: groupWorkSchedule.isFlexible,
                      onChanged: (isFlexible) {
                        setState(() {
                          groupWorkSchedule.isFlexible =
                              isFlexible ?? groupWorkSchedule.isFlexible;
                          for (final detail in groupWorkSchedule.details) {
                            detail.isFlexible = isFlexible ?? detail.isFlexible;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      groupWorkSchedule.details.clear();
                    });
                  },
                  child: const Text('hapus semua', style: labelStyle),
                ),
              ),
            ],
            rows: groupWorkSchedule.details
                .map<DataRow>(
                  (detailSchedule) => DataRow(
                    cells: [
                      DataCell(
                        NumberFormField<int>(
                          initialValue: detailSchedule.shift,
                          onSaved: (value) => detailSchedule.shift =
                              value ?? detailSchedule.shift,
                          validator: (value) {
                            if (value == null) {
                              return 'tidak valid';
                            }
                            if (value <= 0) {
                              return 'harus lebih besar dari 0';
                            }
                            return null;
                          },
                          onChanged: (value) => detailSchedule.shift =
                              value ?? detailSchedule.shift,
                        ),
                      ),
                      DataCell(
                        TimeFormField(
                          controller: detailSchedule.beginWorkController,
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
                          controller: detailSchedule.endWorkController,
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
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isMonday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isMonday =
                                value ?? detailSchedule.isMonday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isTuesday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isTuesday =
                                value ?? detailSchedule.isTuesday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isWednesday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isWednesday =
                                value ?? detailSchedule.isWednesday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isThursday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isThursday =
                                value ?? detailSchedule.isThursday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isFriday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isFriday =
                                value ?? detailSchedule.isFriday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isSaturday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isSaturday =
                                value ?? detailSchedule.isSaturday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isSunday,
                          onChanged: (value) => setState(() {
                            detailSchedule.isSunday =
                                value ?? detailSchedule.isSunday;
                          }),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: detailSchedule.isFlexible,
                          onChanged: (value) => setState(() {
                            detailSchedule.isFlexible =
                                value ?? detailSchedule.isFlexible;
                          }),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () {
                                setState(() {
                                  groupWorkSchedule.details.remove(
                                    detailSchedule,
                                  );
                                });
                              },
                              icon: Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: ElevatedButton(
            onPressed: () => setState(() {
              groupWorkSchedule.details.add(
                DetailSchedule(
                  beginWork: const TimeOfDay(hour: 8, minute: 0),
                  endWork: const TimeOfDay(hour: 22, minute: 0),
                ),
              );
            }),
            child: const Text('Tambah'),
          ),
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
          ),
        ],
        level: 1,
      );

      groupWorkSchedules.add(groupWorkSchedule);
    });
  }

  static const labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  Widget controllersPanel() {
    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() {
            _searchText = val;
          }),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            label: Text('Cari'),
            suffixIcon: Icon(Icons.search),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.black, width: 2),
          ),
          height: 250,
          child: ListView(
            children: controllerList
                .where(
                  (e) =>
                      _searchText.isEmpty ||
                      e.label.insensitiveContains(_searchText),
                )
                .map<Widget>(
                  (controllerData) => ListTile(
                    title: Text(controllerData.label),
                    selected: currentController == controllerData,
                    onTap: () {
                      setState(() {
                        currentController = controllerData;
                      });

                      if (currentController != null) {
                        fetchColumnNames(currentController!);
                        fetchControllerActions(currentController!);
                      }
                    },
                    selectedColor: Colors.green,
                    trailing:
                        currentAction[controllerData.value]?.values.any(
                              (e) => e,
                            ) ==
                            true
                        ? Icon(Icons.circle, size: 15, color: Colors.green)
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget actionPanel() {
    return Column(
      spacing: 15,
      children: [
        Text(
          'Aksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Visibility(
          visible: currentController != null,
          child: Wrap(
            alignment: .start,
            crossAxisAlignment: .start,
            children: actionList
                .map<Widget>(
                  (actionData) => SizedBox(
                    width: 200,
                    child: CheckboxListTile(
                      value:
                          currentAction[currentController?.value]?[actionData
                              .value] ==
                          true,
                      title: Text(actionData.label),
                      onChanged: (val) {
                        if (currentController == null) {
                          return;
                        }
                        if (currentAction[currentController!.value] == null) {
                          currentAction[currentController!.value] = {};
                        }
                        setState(() {
                          currentAction[currentController!.value]![actionData
                                  .value] =
                              val == true;
                        });
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget columnPanel() {
    return Column(
      spacing: 15,
      children: [
        Text(
          'Kolom',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Wrap(
          alignment: .start,
          crossAxisAlignment: .start,
          children: columnList
              .map(
                (column) => SizedBox(
                  width: 200,
                  child: CheckboxListTile(
                    value:
                        currentColumn[currentController?.className]?[column
                            .name] ==
                        true,
                    title: Text(column.humanizeName),
                    onChanged: (val) {
                      if (currentController == null) {
                        return;
                      }
                      if (currentColumn[currentController!.className] == null) {
                        currentColumn[currentController!.className] = {};
                      }
                      setState(() {
                        currentColumn[currentController!.className]![column
                                .name] =
                            val == true;
                      });
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static const double maxWidthControllerPanel = 300;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    codeInputWidget.text = role.name;
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    double height = size.height - padding.top - padding.bottom - 230;
    height = height < 400 ? 400 : height;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: VerticalBodyScroll(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:
                        [
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 600,
                            child: TextFormField(
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Nama',
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(),
                              ),
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
                          const SizedBox(height: 10),

                          Align(
                            alignment: .centerLeft,
                            child: const Text(
                              'Akses Halaman',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(thickness: 3.0),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 800) {
                                return Row(
                                  mainAxisAlignment: .start,
                                  spacing: 15,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: maxWidthControllerPanel,
                                      ),
                                      child: controllersPanel(),
                                    ),
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment: .start,
                                        crossAxisAlignment: .start,
                                        children: [
                                          actionPanel(),
                                          const Divider(),
                                          columnPanel(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  spacing: 10,
                                  children: [
                                    controllersPanel(),
                                    actionPanel(),
                                    const Divider(),
                                    columnPanel(),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Jadwal Kerja",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _addNewGroupSchedule(),
                            child: const Text('Tambah Group Jadwal'),
                          ),
                        ] +
                        workScheduleForms(),
                  ),
                ),
              ),
            ),
            Divider(thickness: 3),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _submit();
                  }
                },
                child: const Text('submit'),
              ),
            ),
          ],
        ),
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
  GroupWorkSchedule({
    this.level = 1,
    this.groupName = '',
    List<DetailSchedule>? details,
    this.isFlexible = false,
    Date? beginActiveAt,
    Date? endActiveAt,
  }) : beginActiveAt = beginActiveAt ?? Date.today(),
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
  bool isMonday;
  bool isTuesday;
  bool isWednesday;
  bool isThursday;
  bool isFriday;
  bool isSaturday;
  bool isSunday;
  int shift;
  TimeOfDay _beginWork;
  TimeOfDay _endWork;
  late final TextEditingController beginWorkController;
  late final TextEditingController endWorkController;
  bool isFlexible;
  DetailSchedule({
    this.shift = 1,
    this.isMonday = false,
    this.isTuesday = false,
    this.isWednesday = false,
    this.isThursday = false,
    this.isFriday = false,
    this.isSaturday = false,
    this.isSunday = false,
    this.isFlexible = false,
    TimeOfDay? beginWork,
    TimeOfDay? endWork,
  }) : _beginWork = beginWork ?? TimeOfDay(hour: 8, minute: 0),
       _endWork = endWork ?? TimeOfDay(hour: 22, minute: 0),
       beginWorkController = TextEditingController(
         text: beginWork?.format24Hour() ?? '08:00',
       ),
       endWorkController = TextEditingController(
         text: endWork?.format24Hour() ?? '22:00',
       );

  TimeOfDay get beginWork => _beginWork;
  TimeOfDay get endWork => _endWork;
  List<int> get dayOfWeeks {
    List<int> result = [];
    if (isMonday) result.add(1);
    if (isTuesday) result.add(2);
    if (isWednesday) result.add(3);
    if (isThursday) result.add(4);
    if (isFriday) result.add(5);
    if (isSaturday) result.add(6);
    if (isSunday) result.add(7);
    return result;
  }

  set beginWork(TimeOfDay value) {
    _beginWork = value;
    beginWorkController.text = value.format24Hour();
  }

  set endWork(TimeOfDay value) {
    _endWork = value;
    endWorkController.text = value.format24Hour();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailSchedule &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode =>
      "$shift-$beginWork-$endWork-${isFlexible.toString()}".hashCode;
}

class ActionData {
  String label;
  String value;
  ActionData({this.label = '', this.value = ''});
}

class ControllerData {
  String label;
  String value;
  ControllerData({this.label = '', this.value = ''});
  String get className => value.toClassify();
}
