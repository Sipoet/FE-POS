import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GeneratePayslipFormPage extends StatefulWidget {
  const GeneratePayslipFormPage({super.key});

  @override
  State<GeneratePayslipFormPage> createState() =>
      _GeneratePayslipFormPageState();
}

class _GeneratePayslipFormPageState extends State<GeneratePayslipFormPage>
    with AutomaticKeepAliveClientMixin {
  DateTime startDate = DateTime.now().copyWith(
      month: DateTime.now().month - 1, day: 26, hour: 0, minute: 0, second: 0);
  DateTime endDate =
      DateTime.now().copyWith(day: 25, hour: 23, minute: 59, second: 59);
  final formKey = GlobalKey<FormState>();
  List<String> _employeeIds = [];
  late final Server _server;
  late final Flash flash;
  late Setting _setting;
  late final GeneratePayslipDatatableSource _source;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _server = context.read<Server>();
    _setting = context.read<Setting>();
    flash = Flash(context);
    _source = GeneratePayslipDatatableSource(setting: _setting);
    super.initState();
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
              child: Container(
                constraints: BoxConstraints.loose(const Size.fromWidth(600)),
                child: Column(
                  children: [
                    DateRangePicker(
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
                    AsyncDropdownMultiple(
                      attributeKey: 'name',
                      multiple: true,
                      label: const Text(
                        'Nama Karyawan',
                        style: labelStyle,
                      ),
                      onChanged: (values) {
                        if (values == null || values.isEmpty) {
                          _employeeIds = [];
                          return;
                        }
                        _employeeIds = values
                            .map<String>((row) => row.toString())
                            .toList();
                      },
                      request: (server, limit, searchText) {
                        return server.get('employees', queryParam: {
                          'field[employee]': 'code,name',
                          'search_text': searchText,
                          'page[limit]': '100',
                        });
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
                                        a.employee.name
                                            .compareTo(b.employee.name) *
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
                                        a.startDate.compareTo(b.startDate) *
                                        num);
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
                                  label: const Text('Gaji Kotor',
                                      style: labelStyle),
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
                                  label: const Text('Gaji Bersih',
                                      style: labelStyle),
                                  onSort: (columnIndex, isAscending) {
                                    final num = isAscending ? 1 : -1;
                                    _source.rows.sort((a, b) =>
                                        a.nettSalary.compareTo(b.nettSalary) *
                                        num);
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
                        )),
                  ],
                ),
              ),
            ),
          )),
    );
  }

  void _generatePayslip() async {
    _server.post('payslips/generate_payslip', body: {
      'employee_ids': _employeeIds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    }).then((response) {
      if (response.statusCode == 201) {
        final responseBody = response.data['data'] as List;
        setState(() {
          final payslip = responseBody
              .map<Payslip>((json) =>
                  Payslip.fromJson(json, included: response.data['included']))
              .toList();
          _source.setData(payslip);
        });
        flash.showBanner(
            messageType: MessageType.success,
            title: 'Sukses',
            description: 'Sukses buat slip gaji');
      } else {
        flash.showBanner(
            messageType: MessageType.failed,
            title: 'gagal buat slip gaji',
            description: response.data['message'] ?? '');
      }
      response.data['data'];
    },
        onError: (error) =>
            _server.defaultErrorResponse(context: context, error: error));
  }
}

class GeneratePayslipDatatableSource extends DataTableSource {
  List<Payslip> rows = [];
  List selected = [];
  List status = [];
  final Setting setting;
  bool isAscending = true;
  int sortColumn = 0;

  GeneratePayslipDatatableSource({required this.setting});

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
      DataCell(SelectableText(payslip.employee.name)),
      DataCell(SelectableText(setting.dateFormat(payslip.startDate))),
      DataCell(SelectableText(setting.dateFormat(payslip.endDate))),
      DataCell(SelectableText(setting.numberFormat(payslip.grossSalary))),
      DataCell(SelectableText(setting.numberFormat(payslip.nettSalary))),
    ];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
