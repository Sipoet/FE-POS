import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payroll_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayrollReportPage extends StatefulWidget {
  const PayrollReportPage({super.key});

  @override
  State<PayrollReportPage> createState() => _PayrollReportPageState();
}

class _PayrollReportPageState extends State<PayrollReportPage>
    with LoadingPopup, DefaultResponse, ColumnTypeFinder {
  TrinaGridStateManager? tableStateManager;
  List<PayrollType> payrollTypes = [];
  List<Employee> employees = [];
  List<TableColumn> tableColumns = [];
  late final Server server;
  late final Flash flash;
  final _focusNode = FocusNode();
  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    super.initState();
    _focusNode.requestFocus();
  }

  DateTime _date = Date.today();

  void searchReport() {
    showLoadingPopup();
    tableStateManager?.removeAllRows();
    final tabManager = context.read<TabManager>();
    fetchReport(reportType: 'json')
        .then(
          (response) {
            if (response.statusCode == 200) {
              final json = response.data;
              final included = json['included'];
              setState(() {
                tableColumns = json['meta']['table_columns'].map<TableColumn>((
                  row,
                ) {
                  return TableColumn(
                    clientWidth: double.parse(
                      (row['client_width'] ?? '200').toString(),
                    ),
                    type: convertToColumnType(row['type'], row),
                    inputOptions: row['input_options'],
                    canFilter: true,
                    name: row['name'],
                    humanizeName: row['humanize_name'],
                  );
                }).toList();
                tableStateManager?.setTableColumns(
                  tableColumns,
                  tabManager: tabManager,
                  showFilter: true,
                );
                for (final row in json['data']) {
                  final model = PayrollReportClass().fromJson(
                    row,
                    included: included ?? [],
                  );
                  tableStateManager?.appendModel(model);
                }
              });
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
          },
        )
        .whenComplete(() => hideLoadingPopup());
  }

  void downloadReport() {
    flash.hide();
    fetchReport(reportType: 'xlsx').then(
      (response) {
        if (response.statusCode != 200) {
          flash.show(
            const Text('gagal simpan ke excel'),
            ToastificationType.error,
          );
          return;
        }
        String filename = response.headers.value('content-disposition') ?? '';
        if (filename.isEmpty) {
          flash.show(
            const Text('gagal filename tidak ditemukan'),
            ToastificationType.error,
          );
          return;
        }
        filename = filename.substring(
          filename.indexOf('filename="') + 10,
          filename.indexOf('xlsx";') + 4,
        );
        var downloader = const FileSaver();
        downloader.download(
          filename,
          response.data,
          'xlsx',
          onSuccess: (String path) {
            flash.showBanner(
              messageType: ToastificationType.success,
              title: 'Sukses download',
              description: 'sukses disimpan di $path',
            );
          },
        );
      },
      onError: (error) {
        defaultErrorResponse(error: error);
      },
    );
  }

  Future fetchReport({String reportType = ''}) {
    final params = {
      'date': _date.toIso8601String(),
      'report_type': reportType,
      'payroll_type_ids[]': payrollTypes
          .map((payrollType) => payrollType.id.toString())
          .toList(),
      'employee_ids[]': employees
          .map((employee) => employee.id.toString())
          .toList(),
    };
    return server.get(
      'payrolls/report',
      responseType: reportType,
      queryParam: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 350,
                    child: DateFormField(
                      focusNode: _focusNode,
                      label: const Text('Tanggal'),
                      initialValue: _date,
                      dateType: DateType(),
                      onChanged: (date) => _date = date ?? _date,
                    ),
                  ),
                  SizedBox(
                    width: 350,
                    child: AsyncDropdownMultiple<Employee>(
                      textOnSearch: (employee) => employee.name,

                      onChanged: (newEmployees) => employees = newEmployees,
                      modelClass: EmployeeClass(),
                    ),
                  ),
                  SizedBox(
                    width: 350,
                    child: AsyncDropdownMultiple<PayrollType>(
                      textOnSearch: (payrollType) => payrollType.name,

                      label: Text('Tipe Payroll'),
                      onChanged: (newPayrollTypes) =>
                          payrollTypes = newPayrollTypes,
                      modelClass: PayrollTypeClass(),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        searchReport();
                      },
                      child: const Text('Search'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      downloadReport();
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(
                height: bodyScreenHeight,
                child: SyncDataTable(
                  columns: tableColumns,
                  showSummary: true,
                  showFilter: true,
                  onLoaded: (stateManager) => tableStateManager = stateManager,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
