import 'dart:io';
import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:provider/provider.dart';

class DiscountMassUploadPage extends StatefulWidget {
  const DiscountMassUploadPage({super.key});

  @override
  State<DiscountMassUploadPage> createState() => _DiscountMassUploadPageState();
}

class _DiscountMassUploadPageState extends State<DiscountMassUploadPage>
    with AutomaticKeepAliveClientMixin {
  List _discounts = <Discount>[];
  late Server _server;
  late Setting _setting;
  List<bool> selected = [];
  @override
  void initState() {
    var sessionState = context.read<SessionState>();
    _server = sessionState.server;
    _setting = context.read<Setting>();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var headerStyle =
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    return SingleChildScrollView(
        child: Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    pickFile();
                  },
                  child: const Text('Pilih file')),
              ElevatedButton(
                child: const Text('Template Excel Mass Upload Diskon'),
                onPressed: () => downloadMassUploadFile(),
              ),
            ],
          ),
          Visibility(
            visible: _discounts.isNotEmpty,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: Text('Kode Supplier', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Merek', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Jenis/Departemen', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Kode Item', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Level', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Diskon1', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Diskon2', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Diskon3', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Diskon4', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Tanggal Mulai', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Tanggal Akhir', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('Status', style: headerStyle),
                  ),
                ],
                rows: List<DataRow>.generate(
                  _discounts.length,
                  (int index) => DataRow(
                    cells: decorateDiscount(_discounts[index]),
                    selected: selected[index],
                    onSelectChanged: (bool? value) {
                      setState(() {
                        selected[index] = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _discounts.isNotEmpty,
            child: ElevatedButton(
              child: const Text('submit'),
              onPressed: () {
                submitDiscount();
              },
            ),
          )
        ],
      ),
    ));
  }

  List<DataCell> decorateDiscount(Discount discount) {
    return <DataCell>[
      DataCell(SelectableText(discount.supplierCode ?? '')),
      DataCell(SelectableText(discount.brandName ?? '')),
      DataCell(SelectableText(discount.itemType ?? '')),
      DataCell(SelectableText(discount.itemCode ?? '')),
      DataCell(SelectableText(discount.weight.toString())),
      DataCell(SelectableText(discount.discount1.toString())),
      DataCell(SelectableText(discount.discount2.toString())),
      DataCell(SelectableText(discount.discount3.toString())),
      DataCell(SelectableText(discount.discount4.toString())),
      DataCell(SelectableText(_setting.dateTimeFormat(discount.startTime))),
      DataCell(SelectableText(_setting.dateTimeFormat(discount.endTime))),
      DataCell(SelectableText(discount.id == null ? 'Draft' : 'Saved')),
    ];
  }

  void downloadMassUploadFile() async {
    var destinationPath = await FilePicker.platform.saveFile(
        fileName: 'template_mass_upload_discount.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx']);
    _server.download(
        'discounts/template_mass_upload_excel', 'xlsx', destinationPath);
  }

  void submitDiscount() {
    for (final (index, Discount discount) in _discounts.indexed) {
      if (selected[index]) {
        createOrUpdateDiscount(discount, index);
      }
    }
  }

  void createOrUpdateDiscount(Discount discount, int index) {
    Map body = {'discount': discount};
    Future request;
    if (discount.id == null) {
      request = _server.post('discounts', body: body);
    } else {
      request = _server.put('discounts/${discount.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        if (discount.id == null) {
          setState(() {
            discount.id = int.tryParse(data['id']);
            discount.code = data['attributes']['code'];
            selected[index] = false;
          });
        }
      }
    });
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    var bytes = File(result.files.single.path!).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    setState(() {
      _discounts = [];
      selected = [];
      for (final (index, row) in excel.tables['master']!.rows.indexed) {
        if (index < 2 || row[5]?.value == null) {
          continue;
        }
        final discount = Discount(
          supplierCode: row[0]?.value.toString(),
          brandName: row[1]?.value.toString(),
          itemType: row[2]?.value.toString(),
          itemCode: row[3]?.value.toString(),
          weight: int.parse(row[4]?.value.toString() ?? ''),
          discount1: Percentage.parse(row[5]?.value?.toString() ?? '0'),
          discount2: Percentage.parse(row[6]?.value?.toString() ?? '0'),
          discount3: Percentage.parse(row[7]?.value?.toString() ?? '0'),
          discount4: Percentage.parse(row[8]?.value?.toString() ?? '0'),
          startTime: DateTime.parse(row[9]?.value.toString() ?? ''),
          endTime: DateTime.parse(row[10]?.value.toString() ?? ''),
        );
        selected.add(true);
        _discounts.add(discount);
      }
    });
  }
}
