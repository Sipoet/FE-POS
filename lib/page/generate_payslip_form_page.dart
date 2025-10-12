import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/page/payslip_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
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
  DateTime startDate = DateTime.now().copyWith(
      month: DateTime.now().month - 1, day: 26, hour: 0, minute: 0, second: 0);
  DateTime endDate =
      DateTime.now().copyWith(day: 25, hour: 23, minute: 59, second: 59);
  final formKey = GlobalKey<FormState>();
  List<String> _employeeIds = [];
  late final Server _server;
  late final Flash flash;
  late Setting _setting;
  final _focusNode = FocusNode();
  late final GeneratePayslipDatatableSource _source;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _server = context.read<Server>();
    _setting = context.read<Setting>();
    final tabManager = context.read<TabManager>();
    flash = Flash();
    _source = GeneratePayslipDatatableSource(
        tabManager: tabManager, setting: _setting);
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
                children: [
                  Container(
                      constraints:
                          BoxConstraints.loose(const Size.fromWidth(600)),
                      child: Column(
                        children: [
                          DateRangeFormField(
                            focusNode: _focusNode,
                            datePickerOnly: true,
                            key: const ValueKey('generate_payslip-periode'),
                            label: const Text(
                              'Periode',
                              style: labelStyle,
                            ),
                            onChanged: (range) {
                              startDate = range!.start;
                              endDate = range.end;
                            },
                            initialDateRange:
                                DateTimeRange(start: startDate, end: endDate),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          AsyncDropdownMultiple<Employee>(
                            key: const ValueKey('generate_payslip-karyawan'),
                            attributeKey: 'name',
                            label: const Text(
                              'Nama Karyawan',
                              style: labelStyle,
                            ),
                            onChanged: (values) {
                              _employeeIds = values
                                  .map<String>((e) => e.id.toString())
                                  .toList();
                            },
                            textOnSearch: (employee) =>
                                "${employee.code} - ${employee.name}",
                            textOnSelected: (employee) => employee.code,
                            modelClass: EmployeeClass(),
                            request: (
                                {int page = 1,
                                int limit = 20,
                                String searchText = '',
                                required CancelToken cancelToken}) {
                              return _server.get('employees',
                                  queryParam: {
                                    'field[employee]': 'code,name',
                                    'search_text': searchText,
                                    'page[limit]': '20',
                                  },
                                  cancelToken: cancelToken);
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  _generatePayslip();
                                }
                              },
                              child: const Text('generate')),
                        ],
                      )),
                  Visibility(
                    visible: _source.rows.isNotEmpty,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Hasil :',
                          style: labelStyle,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        PaginatedDataTable(
                          showFirstLastButtons: true,
                          rowsPerPage: 30,
                          showCheckboxColumn: false,
                          sortAscending: _source.isAscending,
                          sortColumnIndex: _source.sortColumn,
                          columns: [
                            DataColumn(
                              label: const Text('Nama Karyawan',
                                  style: labelStyle),
                              onSort: (columnIndex, isAscending) {
                                final num = isAscending ? 1 : -1;
                                _source.rows.sort((a, b) =>
                                    a.employee.name.compareTo(b.employee.name) *
                                    num);
                                setState(() {
                                  _source.sortColumn = columnIndex;
                                  _source.isAscending = isAscending;
                                  _source.setData(_source.rows);
                                });
                              },
                            ),
                            DataColumn(
                              label: const Text('Periode mulai',
                                  style: labelStyle),
                              onSort: (columnIndex, isAscending) {
                                final num = isAscending ? 1 : -1;
                                _source.rows.sort((a, b) =>
                                    a.startDate.compareTo(b.startDate) * num);
                                setState(() {
                                  _source.sortColumn = columnIndex;
                                  _source.isAscending = isAscending;
                                  _source.setData(_source.rows);
                                });
                              },
                            ),
                            DataColumn(
                              label: const Text('Periode Sampai',
                                  style: labelStyle),
                              onSort: (columnIndex, isAscending) {
                                final num = isAscending ? 1 : -1;
                                _source.rows.sort((a, b) =>
                                    a.endDate.compareTo(b.endDate) * num);
                                setState(() {
                                  _source.sortColumn = columnIndex;
                                  _source.isAscending = isAscending;
                                  _source.setData(_source.rows);
                                });
                              },
                            ),
                            DataColumn(
                              label:
                                  const Text('Gaji Kotor', style: labelStyle),
                              onSort: (columnIndex, isAscending) {
                                final num = isAscending ? 1 : -1;
                                _source.rows.sort((a, b) =>
                                    a.grossSalary.compareTo(b.grossSalary) *
                                    num);
                                setState(() {
                                  _source.sortColumn = columnIndex;
                                  _source.isAscending = isAscending;
                                  _source.setData(_source.rows);
                                });
                              },
                            ),
                            DataColumn(
                              label:
                                  const Text('Gaji Bersih', style: labelStyle),
                              onSort: (columnIndex, isAscending) {
                                final num = isAscending ? 1 : -1;
                                _source.rows.sort((a, b) =>
                                    a.nettSalary.compareTo(b.nettSalary) * num);
                                setState(() {
                                  _source.sortColumn = columnIndex;
                                  _source.isAscending = isAscending;
                                  _source.setData(_source.rows);
                                });
                              },
                            ),
                          ],
                          source: _source,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  void _generatePayslip() async {
    showLoadingPopup();
    _server.post('payslips/generate_payslip', body: {
      'employee_ids': _employeeIds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    }).then((response) {
      if (response.statusCode == 201) {
        final responseBody = response.data['data'] as List;
        setState(() {
          final payslip = responseBody
              .map<Payslip>((json) => PayslipClass()
                  .fromJson(json, included: response.data['included']))
              .toList();
          _source.setData(payslip);
        });
      } else {
        flash.showBanner(
            messageType: ToastificationType.error,
            title: 'gagal buat slip gaji',
            description: response.data['message'] ?? '');
      }
      response.data['data'];
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }
}

class GeneratePayslipDatatableSource extends DataTableSource
    with TextFormatter {
  List<Payslip> rows = [];
  List selected = [];
  List status = [];
  TabManager tabManager;
  final Setting setting;
  bool isAscending = true;
  int sortColumn = 0;

  GeneratePayslipDatatableSource(
      {required this.setting, required this.tabManager});

  void setData(data) {
    rows = data;
    selected = List.generate(rows.length, (index) => true);
    status = List.generate(rows.length, (index) => 'Draft');
    notifyListeners();
  }

  void setStatus(index, newStatus) {
    status[index] = newStatus;
    notifyListeners();
  }

  @override
  int get rowCount => rows.length;

  @override
  DataRow? getRow(int index) {
    return DataRow(
      key: ObjectKey(rows[index]),
      cells: decoratePayslip(index),
      selected: selected[index],
      onSelectChanged: (bool? value) {
        selected[index] = value!;
        notifyListeners();
      },
    );
  }

  List<DataCell> decoratePayslip(int index) {
    final payslip = rows[index];
    return <DataCell>[
      DataCell(
          onTap: () => _openPayslipForm(payslip),
          SelectableText(payslip.employee.name)),
      DataCell(SelectableText(dateFormat(payslip.startDate))),
      DataCell(SelectableText(dateFormat(payslip.endDate))),
      DataCell(SelectableText(numberFormat(payslip.grossSalary))),
      DataCell(SelectableText(numberFormat(payslip.nettSalary))),
    ];
  }

  void _openPayslipForm(Payslip payslip) {
    tabManager.addTab('Edit SLip Gaji ${payslip.id}',
        PayslipFormPage(key: ObjectKey(payslip), payslip: payslip));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
