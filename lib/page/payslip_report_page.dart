import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/model/payslip_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayslipReportPage extends StatefulWidget {
  const PayslipReportPage({super.key});

  @override
  State<PayslipReportPage> createState() => _PayslipReportPageState();
}

class _PayslipReportPageState extends State<PayslipReportPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse, LoadingPopup {
  final formKey = GlobalKey<FormState>();
  PlutoGridStateManager? tableStateManager;
  List<PayrollType> payrollTypes = [];
  List<TableColumn> tableColumns = [];
  PayslipStatus? _payslipStatus;
  EmployeeStatus? _employeeStatus;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(
          month: DateTime.now().month - 1,
          day: 26,
          hour: 0,
          minute: 0,
          second: 0),
      end: DateTime.now().copyWith(day: 25, hour: 23, minute: 59, second: 59));
  final cancelToken = CancelToken();
  @override
  bool get wantKeepAlive => true;
  List<String> _employeeIds = [];
  late final Flash flash;
  @override
  void initState() {
    flash = Flash();
    super.initState();
  }

  void search() {
    showLoadingPopup();
    tableStateManager?.removeAllRows();
    final tabManager = context.read<TabManager>();
    fetchData('json').then((response) {
      if (response.statusCode == 200) {
        final json = response.data;
        final included = json['included'];
        setState(() {
          tableColumns = json['meta']['table_columns'].map<TableColumn>((row) {
            return TableColumn(
                clientWidth:
                    double.parse(row['client_width']?.toString() ?? '200'),
                type: TableColumnType.fromString(row['type']),
                inputOptions: row['input_options'],
                name: row['name'],
                canFilter: row['can_filter'] ?? false,
                canSort: row['can_sort'] ?? false,
                humanizeName: row['humanize_name']);
          }).toList();
          tableStateManager?.setTableColumns(tableColumns,
              tabManager: tabManager);
          for (final row in json['data']) {
            final model = PayslipReport.fromJson(row, included: included ?? []);
            tableStateManager?.appendModel(model, tableColumns);
          }
        });
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future fetchData(String responseType) {
    final server = context.read<Server>();
    return server.get('payslips/report',
        queryParam: {
          'filter[start_date]': _dateRange.start.toIso8601String(),
          'filter[end_date]': _dateRange.end.toIso8601String(),
          'filter[employee_ids]': _employeeIds.join(','),
          'filter[payslip_status]': _payslipStatus?.toString(),
          'filter[employee_status]': _employeeStatus?.toString(),
        },
        cancelToken: cancelToken,
        responseType: responseType);
  }

  void download() {
    flash.hide();
    fetchData('xlsx').then((response) {
      if (response.statusCode == 200) {
        const fileSaver = FileSaver();
        String filename = (response.headers.value('content-disposition') ?? '');
        filename = filename.substring(filename.indexOf('filename="') + 10,
            filename.indexOf('xlsx";') + 4);
        fileSaver.download(
          filename,
          response.data,
          'xlsx',
          onSuccess: (path) {
            flash.showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses download',
                description: 'sukses disimpan di $path');
          },
        );
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 300,
                        child: DateRangeFormField(
                          label: const Text(
                            'Periode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          datePickerOnly: true,
                          initialDateRange: _dateRange,
                          onChanged: (range) =>
                              _dateRange = range ?? _dateRange,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 300,
                        child: DropdownMenu<PayslipStatus>(
                          label: const Text(
                            'Status Slip Gaji',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onSelected: (value) => _payslipStatus = value,
                          dropdownMenuEntries: PayslipStatus.values
                              .map<DropdownMenuEntry<PayslipStatus>>((status) =>
                                  DropdownMenuEntry<PayslipStatus>(
                                      value: status, label: status.humanize()))
                              .toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 300,
                        child: AsyncDropdownMultiple<Employee>(
                          label: const Text(
                            'Karyawan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          textOnSearch: (employee) =>
                              "${employee.code} - ${employee.name}",
                          converter: (json, {included = const [], model}) =>
                              Employee.fromJson(json, included: included),
                          path: 'employees',
                          attributeKey: 'name',
                          onChanged: (value) => _employeeIds = value
                              .map<String>((e) => e.id.toString())
                              .toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 300,
                        child: DropdownMenu<EmployeeStatus>(
                          label: const Text(
                            'Status Karyawan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onSelected: (value) => _employeeStatus = value,
                          dropdownMenuEntries: EmployeeStatus.values
                              .map<DropdownMenuEntry<EmployeeStatus>>(
                                  (status) => DropdownMenuEntry<EmployeeStatus>(
                                      value: status, label: status.humanize()))
                              .toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  search();
                                }
                              },
                              child: const Text('Cari')),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  download();
                                }
                              },
                              child: const Text('Download')),
                        ],
                      )
                    ],
                  )),
              const SizedBox(
                height: 10,
              ),
              const Divider(),
              SizedBox(
                height: 500,
                child: SyncDataTable(
                  columns: tableColumns,
                  showSummary: true,
                  showFilter: true,
                  onLoaded: (stateManager) => tableStateManager = stateManager,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
