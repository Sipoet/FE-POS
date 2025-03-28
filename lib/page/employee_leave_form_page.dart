import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/model/employee_leave.dart';
import 'package:flutter/services.dart';

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
  EmployeeLeave get employeeLeave => widget.employeeLeave;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    super.initState();
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'employee_leave',
        'id': employeeLeave.id,
        'attributes': employeeLeave.toJson()
      }
    };
    Future request;
    if (employeeLeave.id == null) {
      request = server.post('employee_leaves', body: body);
    } else {
      request = server.put('employee_leaves/${employeeLeave.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          employeeLeave.id = int.tryParse(data['id']);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Cuti Karyawan ${employeeLeave.id}');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  Visibility(
                    visible: employeeLeave.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () => fetchHistoryByRecord(
                            'EmployeeLeave', employeeLeave.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  Flexible(
                    child: AsyncDropdown<Employee>(
                      key: const ValueKey('employeeSelect'),
                      path: '/employees',
                      attributeKey: 'name',
                      textOnSearch: (employee) =>
                          "${employee.code} - ${employee.name}",
                      converter: Employee.fromJson,
                      label: const Text(
                        'Nama Karyawan :',
                        style: labelStyle,
                      ),
                      onChanged: (employee) {
                        employeeLeave.employee = employee ?? Employee();
                      },
                      selected: employeeLeave.employee,
                      validator: (value) {
                        if (employeeLeave.employee.id == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DateFormField(
                      datePickerOnly: true,
                      helpText: 'Tanggal Cuti',
                      label: const Text(
                        'Tanggal Cuti',
                        style: labelStyle,
                      ),
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        employeeLeave.date = Date.parsingDateTime(newValue);
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
                        employeeLeave.date = Date.parsingDateTime(newValue);
                      },
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 31)),
                      initialValue: employeeLeave.date),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownMenu<LeaveType>(
                      label: const Text(
                        'Tipe Cuti',
                        style: labelStyle,
                      ),
                      onSelected: (value) => setState(() {
                            employeeLeave.leaveType =
                                value ?? LeaveType.annualLeave;
                            if (employeeLeave.leaveType !=
                                LeaveType.changeDay) {
                              employeeLeave.changeDate = null;
                              employeeLeave.changeShift = null;
                            }
                          }),
                      initialSelection: employeeLeave.leaveType,
                      dropdownMenuEntries: LeaveType.values
                          .map<DropdownMenuEntry<LeaveType>>((leaveType) =>
                              DropdownMenuEntry(
                                  value: leaveType,
                                  label: leaveType.humanize()))
                          .toList()),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: employeeLeave.leaveType == LeaveType.changeDay,
                    child: Column(
                      children: [
                        DateFormField(
                            label: const Text(
                              'Tanggal Ganti Hari',
                              style: labelStyle,
                            ),
                            datePickerOnly: true,
                            helpText: 'Tanggal Ganti Hari',
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
                            firstDate: DateTime(2023),
                            lastDate:
                                DateTime.now().add(const Duration(days: 31)),
                            initialValue: employeeLeave.changeDate),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSaved: (value) {
                            employeeLeave.changeShift =
                                int.tryParse(value ?? '');
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
                          initialValue: employeeLeave.changeShift?.toString(),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text(
                              'Ganti Shift',
                              style: labelStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Keterangan Cuti',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: employeeLeave.description,
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
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            flash.show(
                                const Text('Loading'), ToastificationType.info);
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
