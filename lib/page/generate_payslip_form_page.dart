import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/page/payslip_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
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
  DateTime startDate = DateTime.now().copyWith(
      month: DateTime.now().month - 1, day: 26, hour: 0, minute: 0, second: 0);
  DateTime endDate =
      DateTime.now().copyWith(day: 25, hour: 23, minute: 59, second: 59);
  final formKey = GlobalKey<FormState>();
  List<String> _employeeIds = [];
  late final Server _server;
  late final Flash flash;
  final _focusNode = FocusNode();
  late final TrinaGridStateManager _source;
  late final List<TableColumn> _columns;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _server = context.read<Server>();
    final tabManager = context.read<TabManager>();
    _columns = [
      TableColumn<Payslip>(
        name: 'employee_name',
        humanizeName: 'Nama Karyawan',
        clientWidth: 180,
        frozen: TrinaColumnFrozen.start,
        type: TableColumnType.text,
        getValue: (Model model) {
          Payslip payslip = model as Payslip;
          return payslip.employee.name.toTitleCase();
        },
      ),
      TableColumn(
          name: 'start_date',
          humanizeName: 'Periode Mulai',
          clientWidth: 150,
          type: TableColumnType.date),
      TableColumn(
          name: 'end_date',
          humanizeName: 'Periode Akhir',
          clientWidth: 150,
          type: TableColumnType.date),
      TableColumn(
          name: 'gross_salary',
          humanizeName: 'Gaji Kotor',
          clientWidth: 180,
          type: TableColumnType.money),
      TableColumn(
          name: 'nett_salary',
          humanizeName: 'Gaji Bersih',
          clientWidth: 180,
          type: TableColumnType.money),
      TableColumn(
          name: 'work_days',
          humanizeName: 'Hari Kerja',
          clientWidth: 180,
          type: TableColumnType.number),
      TableColumn(
          name: 'sick_leave',
          humanizeName: 'Jumlah Sakit(Hari)',
          clientWidth: 180,
          type: TableColumnType.number),
      TableColumn(
          name: 'known_absence',
          humanizeName: 'Jumlah Izin(Hari)',
          clientWidth: 180,
          type: TableColumnType.number),
      TableColumn(
          name: 'unknown_absence',
          humanizeName: 'Jumlah Alpha/Tanpa kabar(Hari)',
          clientWidth: 180,
          type: TableColumnType.number),
      TableColumn(
          name: 'detail',
          humanizeName: 'Detail',
          frozen: TrinaColumnFrozen.end,
          clientWidth: 180,
          renderBody: (rendererContext) => Row(
                children: [
                  IconButton(
                      onPressed: () => tabManager.setSafeAreaContent(
                          'Edit Slip Gaji ${rendererContext.row.modelOf<Payslip>().id}',
                          PayslipFormPage(
                              payslip: rendererContext.row.modelOf<Payslip>())),
                      icon: Icon(Icons.edit))
                ],
              ),
          type: TableColumnType.text),
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
                children: [
                  Container(
                      constraints:
                          BoxConstraints.loose(const Size.fromWidth(600)),
                      child: Column(
                        spacing: 10,
                        children: [
                          DateRangeFormField(
                            focusNode: _focusNode,
                            rangeType: DateRangeType(),
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
                          ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  _generatePayslip();
                                }
                              },
                              child: const Text('generate')),
                        ],
                      )),
                  const Text(
                    'Hasil :',
                    style: labelStyle,
                  ),
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
          )),
    );
  }

  void _generatePayslip() async {
    _source.setShowLoading(true);
    _source.removeAllRows();
    _server.post('payslips/generate_payslip', body: {
      'employee_ids': _employeeIds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    }).then((response) {
      if (response.statusCode == 201) {
        final responseBody = response.data['data'] as List;
        setState(() {
          for (final row in responseBody) {
            final payslip = PayslipClass()
                .fromJson(row, included: response.data['included']);
            _source.appendModel(payslip, _columns);
          }
        });
      } else {
        flash.showBanner(
            messageType: ToastificationType.error,
            title: 'gagal buat slip gaji',
            description: response.data['message'] ?? '');
      }
      response.data['data'];
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => _source.setShowLoading(false));
  }
}
