import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/employee_attendance.dart';

import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MassUpdateAllowedOvertimeFormPage extends StatefulWidget {
  const MassUpdateAllowedOvertimeFormPage({super.key});

  @override
  State<MassUpdateAllowedOvertimeFormPage> createState() =>
      _MassUpdateAllowedOvertimeFormPageState();
}

class _MassUpdateAllowedOvertimeFormPageState
    extends State<MassUpdateAllowedOvertimeFormPage>
    with AutomaticKeepAliveClientMixin {
  late Server _server;
  final _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  List<Employee> _employees = [];
  DateTime _dateTime = DateTime.now();
  bool _allowOvertime = true;
  int? _shift;
  late final SyncDataTableSource<EmployeeAttendance> _source;
  late final Flash flash;

  @override
  void initState() {
    _server = context.read<Server>();
    flash = Flash(context);
    final setting = context.read<Setting>();
    _source = SyncDataTableSource<EmployeeAttendance>(
        columns: setting.tableColumn('employeeAttendance'));
    super.initState();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: DateFormField(
                        focusNode: _focusNode,
                        initialValue: _dateTime,
                        label: const Text('Tanggal', style: labelStyle),
                        helpText: 'Tanggal',
                        datePickerOnly: true,
                        onSaved: (value) {
                          _dateTime = value ?? _dateTime;
                        },
                      ),
                    ),
                    Flexible(
                      child: AsyncDropdownMultiple<Employee>(
                        key: const ValueKey('employeeSelect'),
                        path: '/employees',
                        attributeKey: 'name',
                        textOnSearch: (employee) =>
                            "${employee.code} - ${employee.name}",
                        converter: Employee.fromJson,
                        label: const Text(
                          'Karyawan :',
                          style: labelStyle,
                        ),
                        onSaved: (employees) {
                          _employees = employees ?? _employees;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSaved: (value) {
                          setState(() {
                            _shift = int.tryParse(value ?? '');
                          });
                        },
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
                        title: const Text('Boleh Overtime?'),
                        value: _allowOvertime,
                        onChanged: (val) => setState(() {
                              _allowOvertime = val ?? false;
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
                    ),
                    Visibility(
                        visible: _source.sortedData.isNotEmpty,
                        child: SyncDataTable(controller: _source))
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  void _submit() async {
    Map body = {
      'employee_ids[]': _employees.map((e) => e.id).toList(),
      'shift': _shift,
      'date': _dateTime.toIso8601String(),
      'allow_overtime': _allowOvertime,
    };

    _server
        .post('employee_attendances/mass_update_allow_overtime', body: body)
        .then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
            messageType: MessageType.success,
            title: 'Berhasil update Absensi Karyawan');
        final json = response.data;
        final employeeAttendances = json['data']
            .map<EmployeeAttendance>((rawData) => EmployeeAttendance.fromJson(
                rawData,
                included: json['included'] ?? []))
            .toList();
        setState(() {
          _source.setData(employeeAttendances);
        });
      } else {
        final flash = Flash(context);
        flash.showBanner(
            messageType: MessageType.failed,
            title: 'Gagal update Absensi Karyawan',
            description: response.data['message']);
      }
    }, onError: (error) {
      _server.defaultErrorResponse(context: context, error: error);
    });
  }
}