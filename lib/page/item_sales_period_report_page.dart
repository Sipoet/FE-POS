import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_period_report.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/file_saver.dart';

class ItemSalesPeriodReportPage extends StatefulWidget {
  const ItemSalesPeriodReportPage({super.key});

  @override
  State<ItemSalesPeriodReportPage> createState() =>
      _ItemSalesPeriodReportPageState();
}

class _ItemSalesPeriodReportPageState extends State<ItemSalesPeriodReportPage>
    with AutomaticKeepAliveClientMixin {
  final BsSelectBoxController _brandSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _supplierSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _itemTypeSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _itemSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  final _dataSource = CustomDataTableSource<ItemSalesPeriodReport>();
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now().copyWith(hour: 23, minute: 59, second: 59));
  late Flash flash;
  @override
  void initState() {
    SessionState sessionState = context.read<SessionState>();
    flash = Flash(context);
    server = sessionState.server;
    super.initState();
  }

  void _displayReport() async {
    flash.show(
      const Text('Dalam proses.'),
      MessageType.info,
    );
    _reportType = 'json';
    _requestReport().then(_displayDatatable,
        onError: ((error, stackTrace) =>
            server.defaultErrorResponse(context: context, error: error)));
  }

  void _downloadReport() async {
    flash.show(
      const Text('Dalam proses.'),
      MessageType.info,
    );
    _reportType = 'xlsx';
    _requestReport().then(_downloadResponse,
        onError: ((error, stackTrace) =>
            server.defaultErrorResponse(context: context, error: error)));
  }

  Future _requestReport({int? page, int? per}) async {
    List brands =
        _brandSelectWidget.getSelectedAll().map((e) => e.getValue()).toList();
    List suppliers = _supplierSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List itemTypes = _itemTypeSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List items =
        _itemSelectWidget.getSelectedAll().map((e) => e.getValue()).toList();

    return server.get('item_sales/period_report',
        queryParam: {
          'suppliers[]': suppliers,
          'brands[]': brands,
          'item_types[]': itemTypes,
          'items[]': items,
          'report_type': _reportType,
          'start_time': _dateRange.start.toIso8601String(),
          'end_time': _dateRange.end.toIso8601String(),
          if (page != null) 'page': page.toString(),
          if (per != null) 'per': per.toString()
        },
        type: _reportType ?? 'json');
  }

  void _downloadResponse(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      flash.show(const Text('gagal simpan ke excel'), MessageType.failed);
      return;
    }
    String filename = response.headers.value('content-disposition') ?? '';
    if (filename.isEmpty) {
      return;
    }
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);

    var fileSaver = const FileSaver();
    fileSaver.download(filename, response.data, 'xlsx',
        onSuccess: (String path) {
      flash.showBanner(
          messageType: MessageType.success,
          title: 'Sukses download',
          description: 'sukses disimpan di $path');
    });
  }

  void _displayDatatable(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      return;
    }
    var data = response.data;
    setState(() {
      var rawData = data['data'].map<ItemSalesPeriodReport>((row) {
        return ItemSalesPeriodReport.fromJson(row);
      }).toList();
      _dataSource.setData(rawData);
      _isDisplayTable = true;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.of(context).padding;
    double tableHeight =
        MediaQuery.of(context).size.height - padding.top - padding.bottom - 150;
    tableHeight = tableHeight > 600 ? 600 : tableHeight;
    var setting = context.read<Setting>();
    _dataSource.columns = setting.tableColumn('itemSalesPeriodReport');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              direction: Axis.horizontal,
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Tanggal :', style: _filterLabelStyle)),
                      DateRangePicker(
                        startDate: _dateRange.start,
                        endDate: _dateRange.end,
                        onChanged: (range) => _dateRange = range ??
                            DateTimeRange(
                                start: DateTime.now(), end: DateTime.now()),
                      ),
                    ],
                  ),
                ),
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownFormField(
                      label: const Text('Merek :', style: _filterLabelStyle),
                      key: const ValueKey('brandSelect'),
                      controller: _brandSelectWidget,
                      attributeKey: 'merek',
                      path: '/brands',
                    )),
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownFormField(
                      label: const Text('Jenis/Departemen :',
                          style: _filterLabelStyle),
                      key: const ValueKey('brandSelect'),
                      controller: _itemTypeSelectWidget,
                      attributeKey: 'jenis',
                      path: '/item_types',
                    )),
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: AsyncDropdownFormField(
                    label: const Text('Supplier :', style: _filterLabelStyle),
                    key: const ValueKey('supplierSelect'),
                    controller: _supplierSelectWidget,
                    attributeKey: 'nama',
                    path: '/suppliers',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: AsyncDropdownFormField(
                    label: const Text('Item :', style: _filterLabelStyle),
                    key: const ValueKey('itemSelect'),
                    controller: _itemSelectWidget,
                    attributeKey: 'namaitem',
                    path: '/items',
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => {_displayReport()},
                  child: const Text('Tampilkan'),
                ),
                ElevatedButton(
                  onPressed: () => {_downloadReport()},
                  child: const Text('Download'),
                ),
              ],
            ),
            if (_isDisplayTable) const Divider(),
            if (_isDisplayTable)
              SizedBox(
                height: tableHeight,
                child: CustomDataTable(
                  controller: _dataSource,
                  fixedLeftColumns: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
