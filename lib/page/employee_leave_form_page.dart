import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/model/employee_leave.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:provider/provider.dart';

class EmployeeLeaveFormPage extends StatefulWidget {
  final EmployeeLeave employeeLeave;
  const EmployeeLeaveFormPage({super.key, required this.employeeLeave});

  @override
  State<EmployeeLeaveFormPage> createState() => _EmployeeLeaveFormPageState();
}

class _EmployeeLeaveFormPageState extends State<EmployeeLeaveFormPage>
    with AutomaticKeepAliveClientMixin, HistoryPopup, DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  late EmployeeLeave employeeLeave;
  DateTimeRange<Date> _dateRange = DateTimeRange<Date>(
    start: Date.today(),
    end: Date.today(),
  );
  List<EmployeeLeave> _employeeLeaves = [];
  @override
  bool get wantKeepAlive => true;
  late final Server server;
  late final TabManager _tabManager;
  final _descriptionController = TextEditingController();
  final _dateBeforeController = DateEditingController(null);
  final _dateAfterController = DateEditingController(null);
  bool _isMultipleUpdateForm = false;
  @override
  void initState() {
    employeeLeave = widget.employeeLeave;
    _descriptionController.text = employeeLeave.description ?? '';
    _dateAfterController.value = employeeLeave.date;
    _dateBeforeController.value = employeeLeave.changeDate;
    server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    flash = Flash();
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateAfterController.dispose();
    _dateBeforeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (employeeLeave.isNewRecord &&
        employeeLeave.leaveType != LeaveType.changeDay) {
      if (_isMultipleUpdateForm) {
        for (EmployeeLeave empLeave in _employeeLeaves) {
          empLeave.description = employeeLeave.description;
          empLeave.leaveType = employeeLeave.leaveType;
          empLeave.employee = employeeLeave.employee;
          await _save(empLeave).then((newEmpLeave) {
            if (newEmpLeave != null) {
              setState(() {
                empLeave = newEmpLeave;
              });
            }
          });
        }
      } else {
        for (
          DateTime date = _dateRange.start;
          !date.isAfter(_dateRange.end);
          date = date.add(Duration(days: 1))
        ) {
          final row = await _save(
            EmployeeLeave(
              date: date.toDate(),
              description: employeeLeave.description,
              employee: employeeLeave.employee,
              leaveType: employeeLeave.leaveType,
            ),
          );
          if (row != null) {
            _employeeLeaves.add(row);
          }
          setState(() {
            _employeeLeaves;
            _isMultipleUpdateForm = true;
            _tabManager.changeTabHeader(
              widget,
              'Edit Cuti Karyawan ${_employeeLeaves.map<String>((e) => e.id.toString()).join(',')}',
            );
          });
        }
      }
    } else {
      _save(employeeLeave).then((empLeave) {
        if (empLeave != null) {
          setState(() {
            employeeLeave = empLeave;
            _descriptionController.text = employeeLeave.description ?? '';
            _dateAfterController.value = employeeLeave.date;
            _dateBeforeController.value = employeeLeave.changeDate;
          });

          _tabManager.changeTabHeader(
            widget,
            'Edit Cuti Karyawan ${employeeLeave.id}',
          );
        } else {}
      });
    }
  }

  Future<EmployeeLeave?> _save(empLeave) {
    Map body = {
      'data': {
        'type': 'employee_leave',
        'id': empLeave.id,
        'attributes': empLeave.toJson(),
      },
    };
    Future request;
    if (empLeave.id == null) {
      request = server.post('employee_leaves', body: body);
    } else {
      request = server.put('employee_leaves/${empLeave.id}', body: body);
    }
    return request.then(
      (response) {
        if ([200, 201].contains(response.statusCode)) {
          var data = response.data['data'];
          setState(() {
            empLeave.id = int.tryParse(data['id']);
          });
          flash.show(
            const Text('Berhasil disimpan'),
            ToastificationType.success,
          );
          return empLeave;
        } else if (response.statusCode == 409) {
          var data = response.data;
          flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error,
          );
          return null;
        }
        return null;
      },
      onError: (error, stackTrace) {
        defaultErrorResponse(error: error);
        return null;
      },
    );
  }

  void _removeEmployeeLeave(EmployeeLeave empLeave) {
    showConfirmDialog(
      message: "Apakah Yakin Hapus tgl ${empLeave.date?.format()}",
      onSubmit: () {
        empLeave.destroy(server).then((bool isDestroyed) {
          if (isDestroyed) {
            flash.show(
              Text('Sukses hapus tanggal ${empLeave.date?.format()}'),
              ToastificationType.success,
            );
            setState(() {
              _employeeLeaves.remove(empLeave);
            });
          } else {
            flash.showBanner(
              title: 'Gagal hapus tanggal ${empLeave.date?.format()}',
              messageType: ToastificationType.error,
              description: empLeave.errors.join(','),
            );
          }
        });
      },
    );
  }

  static const labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Center(
          child: Column(
            spacing: 10,
            children: [
              Form(
                key: _formKey,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: employeeLeave.id != null,
                        child: ElevatedButton.icon(
                          onPressed: () => fetchHistoryByRecord(
                            'EmployeeLeave',
                            employeeLeave.id,
                          ),
                          label: const Text('Riwayat'),
                          icon: const Icon(Icons.history),
                        ),
                      ),
                      const Divider(),
                      AsyncDropdown<Employee>(
                        key: const ValueKey('employeeSelect'),
                        attributeKey: 'name',
                        textOnSearch: (employee) =>
                            "${employee.code} - ${employee.name}",
                        modelClass: EmployeeClass(),
                        label: const Text('Nama Karyawan :', style: labelStyle),
                        onChanged: (employee) {
                          employeeLeave.employee =
                              employee ?? employeeLeave.employee;
                        },
                        selected: employeeLeave.employee.isNewRecord
                            ? null
                            : employeeLeave.employee,
                        validator: (value) {
                          if (employeeLeave.employee.id == null) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownMenu<LeaveType>(
                        width: 250,
                        label: const Text('Tipe Cuti', style: labelStyle),
                        onSelected: (value) => setState(() {
                          employeeLeave.leaveType =
                              value ?? LeaveType.annualLeave;
                          if (employeeLeave.leaveType != LeaveType.changeDay) {
                            employeeLeave.changeDate = null;
                            _dateBeforeController.value = null;
                            employeeLeave.changeShift = null;
                          }
                        }),
                        initialSelection: employeeLeave.leaveType,
                        dropdownMenuEntries: LeaveType.values
                            .map<DropdownMenuEntry<LeaveType>>(
                              (leaveType) => DropdownMenuEntry(
                                value: leaveType,
                                label: leaveType.humanize(),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible:
                            employeeLeave.leaveType != LeaveType.changeDay &&
                            employeeLeave.isNewRecord,
                        maintainState: true,
                        child: DateRangeFormField(
                          enabled: !_isMultipleUpdateForm,
                          rangeType: DateRangeType(),
                          initialValue: _dateRange,
                          onChanged: (range) => setState(() {
                            _dateRange = range ?? _dateRange;
                          }),
                          allowClear: false,

                          label: const Text('Tanggal Cuti', style: labelStyle),
                        ),
                      ),
                      Visibility(
                        visible:
                            !employeeLeave.isNewRecord ||
                            employeeLeave.leaveType == LeaveType.changeDay,
                        maintainState: true,
                        child: SizedBox(
                          width: 250,
                          child: DateFormField(
                            controller: _dateAfterController,
                            dateType: DateType(),
                            helpText: 'Tanggal Cuti',
                            label: const Text(
                              'Tanggal Cuti',
                              style: labelStyle,
                            ),
                            onSaved: (newValue) {
                              if (newValue == null) {
                                return;
                              }
                              employeeLeave.date = Date.parsingDateTime(
                                newValue,
                              );
                            },
                            validator: (newValue) {
                              if (newValue == null) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                            onChanged: (newValue) {
                              if (newValue == null) {
                                return;
                              }
                              employeeLeave.date = Date.parsingDateTime(
                                newValue,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: employeeLeave.leaveType == LeaveType.changeDay,
                        maintainState: true,
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: .max,
                              mainAxisAlignment: .start,
                              spacing: 15,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: DateFormField(
                                    controller: _dateBeforeController,
                                    label: const Text(
                                      'Tanggal diganti',
                                      style: labelStyle,
                                    ),
                                    dateType: DateType(),
                                    helpText: 'Tanggal diganti Hari',
                                    onSaved: (newValue) {
                                      if (newValue == null) {
                                        employeeLeave.changeDate = null;
                                        return;
                                      }
                                      employeeLeave.changeDate =
                                          Date.parsingDateTime(newValue);
                                    },
                                    validator: (newValue) {
                                      if (newValue == null &&
                                          employeeLeave.leaveType ==
                                              LeaveType.changeDay) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (newValue) {
                                      if (newValue == null) {
                                        employeeLeave.changeDate = null;
                                        return;
                                      }
                                      employeeLeave.changeDate =
                                          Date.parsingDateTime(newValue);
                                    },
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    final date = employeeLeave.date?.toDate();
                                    setState(() {
                                      employeeLeave.date =
                                          employeeLeave.changeDate;
                                      employeeLeave.changeDate = date;
                                      _dateAfterController.value =
                                          employeeLeave.date;
                                      _dateBeforeController.value =
                                          employeeLeave.changeDate;
                                    });
                                  },
                                  icon: Icon(PhosphorIcons.swap()),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSaved: (value) {
                                employeeLeave.changeShift = int.tryParse(
                                  value ?? '',
                                );
                              },
                              onChanged: (value) {
                                employeeLeave.changeShift = int.tryParse(value);
                              },
                              validator: (newValue) {
                                if ((newValue == null || newValue.isEmpty) &&
                                    employeeLeave.leaveType ==
                                        LeaveType.changeDay) {
                                  return 'harus diisi';
                                }
                                return null;
                              },
                              initialValue: employeeLeave.changeShift
                                  ?.toString(),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('Ganti Shift', style: labelStyle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Keterangan Cuti',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder(),
                        ),
                        controller: _descriptionController,
                        maxLines: 4,
                        onSaved: (newValue) {
                          employeeLeave.description = newValue.toString();
                        },
                        onChanged: (newValue) {
                          employeeLeave.description = newValue.toString();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Row(
                          spacing: 20,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  flash.show(
                                    const Text('Loading'),
                                    ToastificationType.info,
                                  );
                                  _submit();
                                }
                              },
                              child: const Text('submit'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (employeeLeave.isNewRecord &&
                                    _employeeLeaves.isEmpty) {
                                  return;
                                }
                                setState(() {
                                  employeeLeave = EmployeeLeaveClass()
                                      .initModel();
                                  _descriptionController.text =
                                      employeeLeave.description ?? '';
                                  _dateAfterController.value =
                                      employeeLeave.date;
                                  _dateBeforeController.value =
                                      employeeLeave.changeDate;
                                  _employeeLeaves.clear();
                                  _isMultipleUpdateForm = false;
                                  _tabManager.changeTabHeader(
                                    widget,
                                    'Buat Cuti Karyawan',
                                  );
                                });
                              },
                              child: const Text('Buat Baru'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _employeeLeaves.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Table(
                    columnWidths: {3: FixedColumnWidth(120)},
                    border: TableBorder.all(),
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Tanggal', style: labelStyle),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Keterangan', style: labelStyle),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Tipe Cuti', style: labelStyle),
                            ),
                          ),
                          TableCell(child: SizedBox()),
                        ],
                      ),
                      ..._employeeLeaves.map<TableRow>(
                        (row) => TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(row.date?.format() ?? ''),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(row.description ?? ''),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(row.leaveType.humanize()),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  spacing: 15,
                                  children: [
                                    IconButton(
                                      onPressed: () => setState(() {
                                        _isMultipleUpdateForm = false;
                                        employeeLeave = row;
                                        _descriptionController.text =
                                            employeeLeave.description ?? '';
                                        _dateAfterController.value =
                                            employeeLeave.date;
                                        _dateBeforeController.value =
                                            employeeLeave.changeDate;
                                        _tabManager.changeTabHeader(
                                          widget,
                                          'Edit Cuti Karyawan ${employeeLeave.id}',
                                        );
                                      }),
                                      icon: Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _removeEmployeeLeave(row),
                                      icon: Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
