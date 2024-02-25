import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_picker.dart';
import 'package:fe_pos/model/employee_leave.dart';

import 'package:provider/provider.dart';

class EmployeeLeaveFormPage extends StatefulWidget {
  final EmployeeLeave employeeLeave;
  const EmployeeLeaveFormPage({super.key, required this.employeeLeave});

  @override
  State<EmployeeLeaveFormPage> createState() => _EmployeeLeaveFormPageState();
}

class _EmployeeLeaveFormPageState extends State<EmployeeLeaveFormPage>
    with AutomaticKeepAliveClientMixin {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  EmployeeLeave get employeeLeave => widget.employeeLeave;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
  }

  void _submit() async {
    var sessionState = context.read<SessionState>();
    var server = sessionState.server;
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
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                  Flexible(
                    child: AsyncDropdownFormField(
                      key: const ValueKey('employeeSelect'),
                      path: '/employees',
                      attributeKey: 'name',
                      label: const Text(
                        'Nama Karyawan :',
                        style: labelStyle,
                      ),
                      onChanged: (option) {
                        employeeLeave.employee.id =
                            int.tryParse(option?[0].getValueAsString() ?? '');
                        final text = option?[0].getText() as Text;
                        employeeLeave.employee.name = text.data ?? '';
                      },
                      selected: [
                        BsSelectBoxOption(
                            value: employeeLeave.employee.id,
                            text: Text(employeeLeave.employee.name)),
                      ],
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
                  DatePicker(
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
                      onSelected: (value) => employeeLeave.leaveType =
                          value ?? LeaveType.annualLeave,
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
                  const SizedBox(
                    height: 10,
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
