import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/employee_attendance_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';

import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmployeeAttendanceReportPage extends StatefulWidget {
  const EmployeeAttendanceReportPage({super.key});

  @override
  State<EmployeeAttendanceReportPage> createState() =>
      _EmployeeAttendanceReportPageState();
}

class _EmployeeAttendanceReportPageState
    extends State<EmployeeAttendanceReportPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, DefaultResponse {
  Date startDate = Date.today()
      .beginningOfMonth()
      .subtract(Duration(days: 1))
      .copyWith(day: 26);
  Date endDate = Date.today().copyWith(day: 25);
  final formKey = GlobalKey<FormState>();
  List<String> _employeeIds = [];
  List<Payroll> _payrolls = [];
  List<Role> _roles = [];
  EmployeeStatus? employeeStatus = .active;
  late final Server _server;
  late final Setting _setting;
  late final Flash flash;
  final _focusNode = FocusNode();
  late final SyncTableController _source;
  late final List<TableColumn> _columns;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _server = context.read<Server>();
    _setting = context.read<Setting>();
    _columns = [
      TableColumn(
        name: 'employee_name',
        humanizeName: 'Nama Karyawan',
        clientWidth: 180,
        frozen: TrinaColumnFrozen.start,
        type: TextTableColumnType(),
      ),
      TableColumn(
        name: 'start_date',
        humanizeName: 'Periode Mulai',
        clientWidth: 150,
        type: DateTableColumnType(DateRangeType()),
      ),
      TableColumn(
        name: 'end_date',
        humanizeName: 'Periode Akhir',
        clientWidth: 150,
        type: DateTableColumnType(DateRangeType()),
      ),
      TableColumn(
        name: 'work_days',
        humanizeName: 'Hari Kerja',
        clientWidth: 180,
        renderBody: (model) {
          model as EmployeeAttendanceReport;
          return Tooltip(
            message:
                "Tanggal Kerja ${model.employeeName}:\n${model.workHourDetails.join(' jam\n')}",
            child: Text(model.workDays.toString(), textAlign: .right),
          );
        },
        type: NumberTableColumnType(DoubleType()),
      ),
      TableColumn(
        name: 'late',
        humanizeName: 'Jumlah Telat(Hari)',
        clientWidth: 180,
        renderBody: (model) {
          model as EmployeeAttendanceReport;
          return Tooltip(
            message:
                "Tanggal Telat ${model.employeeName}:\n${model.lateDates.map((e) => e.format()).join('\n')}",
            child: Text(model.late.toString(), textAlign: .right),
          );
        },
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        name: 'sick_leave',
        humanizeName: 'Jumlah Sakit(Hari)',
        clientWidth: 180,
        renderBody: (model) {
          model as EmployeeAttendanceReport;
          return Tooltip(
            message:
                "Tanggal Sakit ${model.employeeName}:\n${model.sickLeaveDates.map((e) => e.format()).join('\n')}",
            child: Text(model.sickLeave.toString(), textAlign: .right),
          );
        },
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        name: 'known_absence',
        humanizeName: 'Jumlah Izin(Hari)',
        clientWidth: 180,
        renderBody: (model) {
          model as EmployeeAttendanceReport;
          return Tooltip(
            message:
                "Tanggal izin ${model.employeeName}:\n${model.knownAbsenceDates.map((e) => e.format()).join('\n')}",
            child: Text(model.knownAbsence.toString(), textAlign: .right),
          );
        },
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        name: 'unknown_absence',
        humanizeName: 'Jumlah Alpha/Tanpa kabar(Hari)',
        clientWidth: 180,
        renderBody: (model) {
          model as EmployeeAttendanceReport;
          return Tooltip(
            message:
                "Tanggal Alpha ${model.employeeName}:\n${model.unknownAbsenceDates.map((e) => e.format()).join('\n')}",
            child: Text(model.unknownAbsence.toString(), textAlign: .right),
          );
        },
        type: NumberTableColumnType(IntegerType()),
      ),
    ];

    flash = Flash();
    super.initState();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Form(
            key: formKey,
            child: Column(
              spacing: 10,
              crossAxisAlignment: .start,
              children: [
                Wrap(
                  spacing: 15,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 300,
                      child: DateRangeFormField(
                        focusNode: _focusNode,
                        rangeType: DateRangeType(),
                        onChanged: (range) {
                          startDate = range!.start;
                          endDate = range.end;
                        },
                        initialValue: DateTimeRange<Date>(
                          start: startDate,
                          end: endDate,
                        ),
                        label: const Text('Periode', style: labelStyle),
                      ),
                    ),
                    Visibility(
                      visible: _setting.isAuthorize('payrolls', 'read'),
                      child: SizedBox(
                        width: 300,
                        child: AsyncDropdownMultiple<Payroll>(
                          label: const Text('Payroll', style: labelStyle),
                          onChanged: (values) {
                            _payrolls = values;
                          },
                          textOnSearch: (payroll) => payroll.name,
                          modelClass: PayrollClass(),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _setting.isAuthorize('roles', 'read'),
                      child: SizedBox(
                        width: 300,
                        child: AsyncDropdownMultiple<Role>(
                          label: const Text('Jabatan', style: labelStyle),
                          onChanged: (values) => _roles = values,
                          textOnSearch: (role) => role.name,
                          modelClass: RoleClass(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: AsyncDropdownMultiple<Employee>(
                        label: const Text('Nama Karyawan', style: labelStyle),
                        onChanged: (values) {
                          _employeeIds = values
                              .map<String>((e) => e.id.toString())
                              .toList();
                        },
                        textOnSearch: (employee) =>
                            "${employee.code} - ${employee.name}",
                        textOnSelected: (employee) => employee.code,
                        modelClass: EmployeeClass(),
                      ),
                    ),
                    DropdownMenu<EmployeeStatus?>(
                      width: 300,
                      label: Text('Status Karyawan'),
                      initialSelection: employeeStatus,
                      dropdownMenuEntries:
                          EmployeeStatus.values
                              .map(
                                (e) => DropdownMenuEntry<EmployeeStatus?>(
                                  value: e,
                                  label: e.humanize(),
                                ),
                              )
                              .toList()
                            ..insert(
                              0,
                              DropdownMenuEntry<EmployeeStatus?>(
                                value: null,
                                label: '',
                              ),
                            ),
                      onSelected: (value) => setState(() {
                        employeeStatus = value;
                      }),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _generateReporr();
                    }
                  },
                  child: const Text('generate'),
                ),
                const Text('Hasil :', style: labelStyle),
                Container(
                  constraints: BoxConstraints(maxHeight: bodyScreenHeight),
                  child: SyncDataTable<EmployeeAttendanceReport>(
                    showFilter: true,
                    onLoaded: (stateManager) => _source = stateManager,
                    columns: _columns,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generateReporr() async {
    _source.setShowLoading(true);
    _server
        .get(
          'employee_attendances/report',
          queryParam: {
            'employee_ids[]': _employeeIds,
            if (employeeStatus != null)
              'employee_status': employeeStatus.toString(),
            'payroll_ids[]': _payrolls
                .map<String>((e) => e.id.toString())
                .toList(),
            'role_ids[]': _roles.map<String>((e) => e.id.toString()).toList(),
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            final responseBody = response.data['data'] as List;
            setState(() {
              final payslips = responseBody
                  .map<EmployeeAttendanceReport>(
                    (row) => EmployeeAttendanceReportClass().fromJson(
                      row,
                      included: response.data['included'] ?? [],
                    ),
                  )
                  .toList();

              _source.setModels(payslips);
            });
          } else {
            flash.showBanner(
              messageType: ToastificationType.error,
              title: 'gagal buat laporan absensi karyawan',
              description: response.data['message'] ?? '',
            );
          }
          response.data['data'];
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => _source.setShowLoading(false));
  }
}
