import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/time_form_field.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/employee_attendance.dart';

import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

class EmployeeAttendanceFormPage extends StatefulWidget {
  final EmployeeAttendance employeeAttendance;
  const EmployeeAttendanceFormPage(
      {super.key, required this.employeeAttendance});

  @override
  State<EmployeeAttendanceFormPage> createState() =>
      _EmployeeAttendanceFormPageState();
}

class _EmployeeAttendanceFormPageState extends State<EmployeeAttendanceFormPage>
    with AutomaticKeepAliveClientMixin {
  late Server _server;
  final _formKey = GlobalKey<FormState>();
  List<bool> selected = [];
  late final Flash flash;

  EmployeeAttendance get employeeAttendance => widget.employeeAttendance;
  @override
  void initState() {
    flash = Flash(context);
    _server = context.read<Server>();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

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
              alignment: Alignment.center,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        onSaved: (employee) {
                          employeeAttendance.employee = employee ?? Employee();
                        },
                        selected: employeeAttendance.employee,
                        validator: (value) {
                          if (employeeAttendance.employee.id == null) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: DateFormField(
                        initialValue: employeeAttendance.date,
                        label: const Text('Tanggal', style: labelStyle),
                        helpText: 'Tanggal',
                        datePickerOnly: true,
                        onSaved: (value) {
                          if (value != null) {
                            employeeAttendance.startTime =
                                employeeAttendance.startTime.copyWith(
                                    year: value.year,
                                    month: value.month,
                                    day: value.day);
                            employeeAttendance.endTime =
                                employeeAttendance.endTime.copyWith(
                                    year: value.year,
                                    month: value.month,
                                    day: value.day);
                          }
                        },
                      ),
                    ),
                    TimeFormField(
                        label: const Text(
                          'Jam Masuk',
                          style: labelStyle,
                        ),
                        helpText: 'Jam Masuk',
                        onSaved: (value) {
                          if (value != null) {
                            employeeAttendance.startTime =
                                employeeAttendance.startTime.copyWith(
                                    hour: value.hour, minute: value.minute);
                          }
                        },
                        initialValue: employeeAttendance.startWork),
                    TimeFormField(
                        label: const Text(
                          'Jam Keluar',
                          style: labelStyle,
                        ),
                        helpText: 'Jam Keluar',
                        onSaved: (value) {
                          if (value != null) {
                            employeeAttendance.endTime =
                                employeeAttendance.endTime.copyWith(
                                    hour: value.hour, minute: value.minute);
                          }
                        },
                        initialValue: employeeAttendance.endWork),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSaved: (value) {
                          setState(() {
                            employeeAttendance.shift =
                                int.tryParse(value ?? '') ?? 0;
                          });
                        },
                        initialValue: employeeAttendance.shift.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text(
                            'Shift',
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                        title: const Text('Terlambat?'),
                        value: employeeAttendance.isLate,
                        onChanged: (val) => setState(() {
                              employeeAttendance.isLate = val ?? false;
                            })),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              flash.show(
                                  const Text('Loading'), MessageType.info);
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
        ));
  }

  void _submit() async {
    Map body = {
      'data': {
        'type': 'employee_attendance',
        'id': employeeAttendance.id,
        'attributes': employeeAttendance.toJson()
      }
    };
    Future request;
    if (employeeAttendance.id == null) {
      request = _server.post('employee_attendances', body: body);
    } else {
      request = _server.put('employee_attendances/${employeeAttendance.id}',
          body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          employeeAttendance.id = int.tryParse(data['id']);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Absensi Karyawan ${employeeAttendance.id}');
        });

        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      _server.defaultErrorResponse(context: context, error: error);
    });
  }
}
