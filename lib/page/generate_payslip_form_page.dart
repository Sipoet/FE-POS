import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/page/payslip_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';

import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GeneratePayslipFormPage extends StatefulWidget {
  const GeneratePayslipFormPage({super.key});

  @override
  State<GeneratePayslipFormPage> createState() =>
      _GeneratePayslipFormPageState();
}

class _GeneratePayslipFormPageState extends State<GeneratePayslipFormPage>
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
  EmployeeStatus? employeeStatus;
  late final Server _server;
  late final Flash flash;
  final _focusNode = FocusNode();
  late final SyncTableController _source;
  late final List<TableColumn> _columns;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _server = context.read<Server>();
    final tabManager = context.read<TabManager>();
    _columns = [
      TableColumn(
        name: 'employee_name',
        humanizeName: 'Nama Karyawan',
        clientWidth: 180,
        frozen: TrinaColumnFrozen.start,
        type: TextTableColumnType(),
        getValue: (model) {
          if (model is Payslip) {
            return model.employee.name.toTitleCase();
          } else if (model is Employee) {
            return model.name.toTitleCase();
          }
          return model.toString();
        },
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
        name: 'gross_salary',
        humanizeName: 'Gaji Kotor',
        clientWidth: 180,
        type: MoneyTableColumnType(),
      ),
      TableColumn(
        name: 'nett_salary',
        humanizeName: 'Gaji Bersih',
        clientWidth: 180,
        type: MoneyTableColumnType(),
      ),
      TableColumn(
        name: 'work_days',
        humanizeName: 'Hari Kerja',
        clientWidth: 180,
        type: NumberTableColumnType(DoubleType()),
      ),
      TableColumn(
        name: 'sick_leave',
        humanizeName: 'Jumlah Sakit(Hari)',
        clientWidth: 180,
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        name: 'known_absence',
        humanizeName: 'Jumlah Izin(Hari)',
        clientWidth: 180,
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        name: 'unknown_absence',
        humanizeName: 'Jumlah Alpha/Tanpa kabar(Hari)',
        clientWidth: 180,
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn<Payslip>(
        name: 'detail',
        humanizeName: 'Detail',
        frozen: TrinaColumnFrozen.end,
        clientWidth: 180,
        renderBody: (model) => Row(
          children: [
            IconButton(
              onPressed: () => tabManager.setSafeAreaContent(
                'Edit Slip Gaji ${model.id}',
                PayslipFormPage(payslip: model as Payslip),
              ),
              icon: Icon(Icons.edit),
            ),
          ],
        ),
        type: TextTableColumnType(),
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
                    SizedBox(
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
                    SizedBox(
                      width: 300,
                      child: AsyncDropdownMultiple<Role>(
                        label: const Text('Jabatan', style: labelStyle),
                        onChanged: (values) => _roles = values,
                        textOnSearch: (role) => role.name,
                        modelClass: RoleClass(),
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
                      _generatePayslip();
                    }
                  },
                  child: const Text('generate'),
                ),
                const Text('Hasil :', style: labelStyle),
                Container(
                  constraints: BoxConstraints(maxHeight: bodyScreenHeight),
                  child: SyncDataTable<Payslip>(
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

  void _generatePayslip() async {
    _source.setShowLoading(true);
    _server
        .post(
          'payslips/generate_payslip',
          body: {
            'employee_ids': _employeeIds,
            if (employeeStatus != null)
              'employee_status': employeeStatus.toString(),
            'payroll_ids': _payrolls
                .map<String>((e) => e.id.toString())
                .toList(),
            'role_ids': _roles.map<String>((e) => e.id.toString()).toList(),
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          },
        )
        .then((response) {
          if (response.statusCode == 201) {
            final responseBody = response.data['data'] as List;
            setState(() {
              final payslips = responseBody
                  .map<Payslip>(
                    (row) => PayslipClass().fromJson(
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
              title: 'gagal buat slip gaji',
              description: response.data['message'] ?? '',
            );
          }
          response.data['data'];
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => _source.setShowLoading(false));
  }
}
