import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DiscountMassUploadPage extends StatefulWidget {
  const DiscountMassUploadPage({super.key});

  @override
  State<DiscountMassUploadPage> createState() => _DiscountMassUploadPageState();
}

class _DiscountMassUploadPageState extends State<DiscountMassUploadPage>
    with AutomaticKeepAliveClientMixin {
  List<Discount> _discounts = <Discount>[];
  late Server _server;
  late Setting _setting;
  late final DiscountMassUploadDatatableSource _source;
  List<bool> selected = [];
  @override
  void initState() {
    _server = context.read<Server>();
    _setting = context.read<Setting>();
    _source = DiscountMassUploadDatatableSource(setting: _setting);
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
            child: SizedBox(
              child: PaginatedDataTable(
                showFirstLastButtons: true,
                rowsPerPage: 10,
                columns: [
                  DataColumn(
                    label: Text('Kode Diskon', style: headerStyle),
                  ),
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
                    label: Text('Tipe Kalkulasi', style: headerStyle),
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
                source: _source,
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

  void downloadMassUploadFile() async {
    var fileSaver = const FileSaver();
    String? path = await fileSaver.downloadPath(
        'template_mass_upload_discount.xlsx', 'xlsx');
    if (path != null) {
      _server.download('discounts/template_mass_upload_excel', 'xlsx', path);
    }
  }

  void submitDiscount() async {
    for (final (index, Discount discount) in _discounts.indexed) {
      if (_source.selected[index]) {
        await createOrUpdateDiscount(discount, index);
      }
    }
  }

  Future createOrUpdateDiscount(Discount discount, int index) async {
    Map body = {
      'data': {
        'type': 'discount',
        'attributes': discount.toJson(),
        'relationships': {
          'discount_items': {
            'data': discount.discountItems
                .map<Map>((discountItem) => {
                      'id': discountItem.id,
                      'type': 'discount_item',
                      'attributes': discountItem.toJson(),
                    })
                .toList(),
          },
          'discount_item_types': {
            'data': discount.discountItemTypes
                .map<Map>((discountItemType) => {
                      'id': discountItemType.id,
                      'type': 'discount_item_type',
                      'attributes': discountItemType.toJson(),
                    })
                .toList(),
          },
          'discount_suppliers': {
            'data': discount.discountSuppliers
                .map<Map>((discountSupplier) => {
                      'id': discountSupplier.id,
                      'type': 'discount_supplier',
                      'attributes': discountSupplier.toJson(),
                    })
                .toList(),
          },
          'discount_brands': {
            'data': discount.discountBrands
                .map<Map>((discountBrand) => {
                      'id': discountBrand.id,
                      'type': 'discount_brand',
                      'attributes': discountBrand.toJson(),
                    })
                .toList(),
          }
        }
      }
    };
    debugPrint(body.toString());
    dynamic request;
    if (discount.id == null) {
      request = await _server.post('discounts', body: body);
    } else {
      request = await _server.put('discounts/${discount.id}', body: body);
    }
    if ([200, 201].contains(request.statusCode)) {
      var data = request.data['data'];
      setState(() {
        if (discount.id == null) {
          discount.id = int.tryParse(data['id']);
          discount.code = data['attributes']['code'];
        }
        _source.selected[index] = false;
        _source.setStatus(index, 'saved');
      });
    } else {
      debugPrint(request.data['errors'].toString());
      setState(() {
        _source.setStatus(index, 'failed');
      });
    }

    return request;
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    var bytes = await XFile(result.files.single.path!).readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    setState(() {
      _discounts = [];
      for (final (index, row) in excel.tables['master']!.rows.indexed) {
        if (index < 2 || row[5]?.value == null || row[11]?.value == null) {
          continue;
        }
        var discount = Discount(
          code: row[0]?.value.toString() ?? '',
          calculationType: row[5]?.value.toString() == 'percentage'
              ? DiscountCalculationType.percentage
              : DiscountCalculationType.nominal,
          weight: int.tryParse(row[6]?.value?.toString() ?? '') ?? 0,
          discount1: Percentage.parse(row[7]?.value?.toString() ?? '0') / 100,
          discount2: Percentage.parse(row[8]?.value?.toString() ?? '0') / 100,
          discount3: Percentage.parse(row[9]?.value?.toString() ?? '0') / 100,
          discount4: Percentage.parse(row[10]?.value?.toString() ?? '0') / 100,
          startTime: DateTime.parse(row[11]?.value.toString() ?? ''),
          endTime: DateTime.parse(row[12]?.value.toString() ?? ''),
        );
        List? supplierCodes =
            _cleanText(row[1]?.value?.toString())?.split(',').toList();
        if (supplierCodes != null) {
          discount.discountSuppliers = supplierCodes
              .map<DiscountSupplier>(
                  (value) => DiscountSupplier(supplier: Supplier(code: value)))
              .toList();
          discount.supplierCode = discount.discountSuppliers.first.supplierCode;
        }
        List? brandNames =
            _cleanText(row[2]?.value?.toString())?.split(',').toList();
        if (brandNames != null) {
          discount.discountBrands = brandNames
              .map<DiscountBrand>(
                  (value) => DiscountBrand(brand: Brand(name: value)))
              .toList();
          discount.brandName = discount.discountBrands.first.brandName;
        }
        List? itemTypeCodes =
            _cleanText(row[3]?.value?.toString())?.split(',').toList();
        if (itemTypeCodes != null) {
          discount.discountItemTypes = itemTypeCodes
              .map<DiscountItemType>(
                  (value) => DiscountItemType(itemType: ItemType(name: value)))
              .toList();
          discount.itemType = discount.discountItemTypes.first.itemTypeName;
        }
        List? itemCodes =
            _cleanText(row[4]?.value?.toString())?.split(',').toList();
        if (itemCodes != null) {
          discount.discountItems = itemCodes
              .map<DiscountItem>(
                  (value) => DiscountItem(item: Item(code: value)))
              .toList();
          discount.itemCode = discount.discountItems.first.itemCode;
        }

        _discounts.add(discount);
      }

      _source.setData(_discounts);
    });
  }
}

String? _cleanText(String? value) {
  if (value == null) return value;
  return value.replaceAll('\r', '').replaceAll('\n', '');
}

class DiscountMassUploadDatatableSource extends DataTableSource
    with TextFormatter {
  List<Discount> rows = [];
  List selected = [];
  List status = [];
  final Setting setting;

  DiscountMassUploadDatatableSource({required this.setting});

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
      cells: decorateDiscount(index),
      selected: selected[index],
      onSelectChanged: (bool? value) {
        selected[index] = value!;
        notifyListeners();
      },
    );
  }

  List<DataCell> decorateDiscount(int index) {
    final discount = rows[index];
    return <DataCell>[
      DataCell(SelectableText(discount.code)),
      DataCell(SelectableText(discount.supplierCode ?? '')),
      DataCell(SelectableText(discount.brandName ?? '')),
      DataCell(SelectableText(discount.itemType ?? '')),
      DataCell(SelectableText(discount.itemCode ?? '')),
      DataCell(SelectableText(discount.calculationType.toString())),
      DataCell(SelectableText(discount.weight.toString())),
      DataCell(SelectableText(discount.discount1.toString())),
      DataCell(SelectableText(discount.discount2.toString())),
      DataCell(SelectableText(discount.discount3.toString())),
      DataCell(SelectableText(discount.discount4.toString())),
      DataCell(SelectableText(dateTimeFormat(discount.startTime))),
      DataCell(SelectableText(dateTimeFormat(discount.endTime))),
      DataCell(SelectableText(status[index] ?? 'Draft')),
    ];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
