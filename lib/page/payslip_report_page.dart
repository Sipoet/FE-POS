import 'package:fe_pos/model/payslip_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayslipReportPage extends StatefulWidget {
  const PayslipReportPage({super.key});

  @override
  State<PayslipReportPage> createState() => _PayslipReportPageState();
}

class _PayslipReportPageState extends State<PayslipReportPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  final formKey = GlobalKey<FormState>();
  DateTimeRange _dateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  final cancelToken = CancelToken();
  final _source = CustomDataTableSource<PayslipReport>();
  @override
  bool get wantKeepAlive => true;
  List<String> _employeeIds = [];
  @override
  void initState() {
    final setting = context.read<Setting>();
    _source.columns = setting.tableColumn('payslipReport');
    super.initState();
  }

  void search() {
    fetchData('json').then((response) {
      if (response.statusCode == 200) {
        setState(() {
          _source.setData(response.data['data']
              .map<PayslipReport>((json) => PayslipReport.fromJson(json,
                  included: response.data['included'] ?? []))
              .toList());
        });
      }
    }, onError: (error) => defaultErrorResponse(error: error));
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
        },
        cancelToken: cancelToken,
        responseType: responseType);
  }

  void download() {
    fetchData('xlsx').then((response) {
      if (response.statusCode == 200) {
        const fileSaver = FileSaver();
        String filename = (response.headers.value('content-disposition') ?? '');
        filename = filename.substring(filename.indexOf('filename="') + 10,
            filename.indexOf('xlsx";') + 4);
        fileSaver.download(filename, response.data, 'xlsx');
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
                        child: DateRangePicker(
                          label: const Text(
                            'Periode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                        child: AsyncDropdownMultiple(
                          label: const Text(
                            'Karyawan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          multiple: true,
                          path: 'employees',
                          attributeKey: 'name',
                          onChanged: (value) => _employeeIds = value == null
                              ? []
                              : value.map<String>((e) => e.toString()).toList(),
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
              Visibility(
                visible: true,
                child: SizedBox(
                  height: 600,
                  child: CustomDataTable(
                    controller: _source,
                    fixedLeftColumns: 1,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
