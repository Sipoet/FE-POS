import 'package:fe_pos/model/payroll_report.dart';
import 'package:fe_pos/model/payroll_type.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
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
    with LoadingPopup, DefaultResponse {
  PlutoGridStateManager? tableStateManager;
  List<PayrollType> payrollTypes = [];
  List<TableColumn> tableColumns = [];
  late final Server server;
  late final Flash flash;
  final _focusNode = FocusNode();
  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    super.initState();
    _focusNode.requestFocus();
  }

  DateTime _date = Date.today();

  void searchReport() {
    showLoadingPopup();
    tableStateManager?.removeAllRows();
    fetchReport(reportType: 'json').then((response) {
      if (response.statusCode == 200) {
        final json = response.data;
        final included = json['included'];
        setState(() {
          tableColumns = json['meta']['table_columns'].map<TableColumn>((row) {
            return TableColumn(
                width: double.parse(row['table_width'] ?? '200'),
                type: row['type'],
                attributeKey: row['attribute_key'],
                sortKey: row['sort_key'],
                key: row['name'],
                name: row['humanize_name']);
          }).toList();
          tableStateManager?.setTableColumns(tableColumns);
          for (final row in json['data']) {
            final model = PayrollReport.fromJson(row, included: included ?? []);
            tableStateManager?.appendModel(model);
          }
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  void downloadReport() {
    flash.hide();
    fetchReport(reportType: 'xlsx').then((response) {
      if (response.statusCode != 200) {
        flash.show(const Text('gagal simpan ke excel'), MessageType.failed);
        return;
      }
      String filename = response.headers.value('content-disposition') ?? '';
      if (filename.isEmpty) {
        flash.show(
            const Text('gagal filename tidak ditemukan'), MessageType.failed);
        return;
      }
      filename = filename.substring(
          filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
      var downloader = const FileSaver();
      downloader.download(filename, response.data, 'xlsx',
          onSuccess: (String path) {
        flash.showBanner(
            messageType: MessageType.success,
            title: 'Sukses download',
            description: 'sukses disimpan di $path');
      });
    }, onError: (error) {
      defaultErrorResponse(error: error);
    });
  }

  Future fetchReport({String reportType = ''}) {
    final params = {
      'date': _date.toIso8601String(),
      'report_type': reportType,
      'payroll_type_ids[]':
          payrollTypes.map((payrollType) => payrollType.id.toString()).toList()
    };
    return server.get('payrolls/report',
        responseType: reportType, queryParam: params);
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
                SizedBox(
                  width: 350,
                  child: DateFormField(
                    focusNode: _focusNode,
                    label: const Text('Tanggal'),
                    initialValue: _date,
                    datePickerOnly: true,
                    onChanged: (date) => _date = date ?? _date,
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: AsyncDropdownMultiple<PayrollType>(
                      textOnSearch: (payrollType) => payrollType.name,
                      path: 'payroll_types',
                      onChanged: (payrollTypes) => payrollTypes = payrollTypes,
                      converter: PayrollType.fromJson),
                ),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                        onPressed: () {
                          searchReport();
                        },
                        child: const Text('Search')),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        downloadReport();
                      },
                      child: const Text('Download')),
                ]),
                const Divider(),
                SizedBox(
                  height: 500,
                  child: SyncDataTable2(
                    columns: tableColumns,
                    showSummary: true,
                    onLoaded: (stateManager) =>
                        tableStateManager = stateManager,
                  ),
                )
              ]),
        ),
      ),
    );
  }
}
