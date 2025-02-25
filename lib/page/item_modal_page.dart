import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemModalPage extends StatefulWidget {
  final String? barcode;
  final String? itemTypeName;
  final String? supplierCode;
  final String? brandName;
  const ItemModalPage(
      {super.key,
      this.barcode,
      this.itemTypeName,
      this.supplierCode,
      this.brandName});

  @override
  State<ItemModalPage> createState() => _ItemModalPageState();
}

class _ItemModalPageState extends State<ItemModalPage> with DefaultResponse {
  String? itemTypeName;
  String? supplierCode;
  String? brandName;
  late String searchText;
  late final Setting _setting;
  late final Server _server;
  List<ItemReport> itemReports = [];
  Item? selectedItem;
  PlutoGridStateManager? _source;
  final _whiteListColumnNames = [
    'item_code',
    'item_name',
    'store_stock',
    'item_type_name',
    'sell_price',
    'brand_name',
    'supplier_code',
  ];
  List<TableColumn> tableColumns = [];
  @override
  void initState() {
    searchText = widget.barcode ?? '';
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    final columns = _setting.tableColumn('itemReport');
    tableColumns = _whiteListColumnNames
        .map<TableColumn>(
            (name) => columns.firstWhere((column) => column.name == name))
        .toList();

    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 650),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              SizedBox(
                width: 450,
                height: 45,
                child: TextFormField(
                  initialValue: searchText,
                  onFieldSubmitted: (value) {
                    searchText = value;
                    _search();
                  },
                  onChanged: (value) => searchText = value,
                  decoration: const InputDecoration(
                    label: Text('Kata Kunci'),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: AsyncDropdown<ItemType>(
                  path: '/item_types',
                  textOnSelected: (itemType) => itemType.name,
                  textOnSearch: (itemType) =>
                      '${itemType.name} - ${itemType.description}',
                  converter: ItemType.fromJson,
                  label: const Text('Jenis/Departemen'),
                  onChanged: (itemType) => setState(() {
                    itemTypeName = itemType?.name;
                  }),
                ),
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: AsyncDropdown<Brand>(
                  path: '/brands',
                  textOnSelected: (brand) => brand.name,
                  textOnSearch: (brand) =>
                      '${brand.name} - ${brand.description}',
                  converter: Brand.fromJson,
                  label: const Text('Merek'),
                  onChanged: (brand) => setState(() {
                    brandName = brand?.name;
                  }),
                ),
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: AsyncDropdown<Supplier>(
                  path: '/suppliers',
                  textOnSelected: (supplier) => supplier.name,
                  textOnSearch: (supplier) =>
                      '${supplier.code} - ${supplier.name}',
                  converter: Supplier.fromJson,
                  label: const Text('Suppliers'),
                  onChanged: (supplier) => setState(() {
                    supplierCode = supplier?.code;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(onPressed: _search, child: const Text('Cari')),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 1200,
            height: 500,
            child: SyncDataTable2<ItemReport>(
              columns: tableColumns,
              rows: itemReports,
              onSelected: (event) {
                if (event.rowIdx != null) {
                  selectedItem = itemReports[event.rowIdx!]?.item;
                }
              },
              showFilter: false,
              onLoaded: (stateManager) {
                _source = stateManager;
                _source?.setShowLoading(true);
              },
              onRowDoubleTap: (event) {
                selectedItem = itemReports[event.rowIdx]?.item;
                _select();
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                  onPressed: _select,
                  label: const Text('Pilih')),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup')),
            ],
          ),
        ],
      ),
    );
  }

  void _search() {
    _source?.setShowLoading(true);
    Map<String, dynamic> param = {
      'page[page]': '1',
      'page[limit]': '500',
      'report_type': 'json',
      'sort': 'item_code',
      'search_text': searchText,
      'include': 'item,item.discount_rules'
    };
    if (itemTypeName != null) {
      param['filter[item_type_name][eq]'] = itemTypeName;
    }
    if (brandName != null) {
      param['filter[brand_name][eq]'] = brandName;
    }
    if (supplierCode != null) {
      param['filter[supplier_code][eq]'] = supplierCode;
    }
    _server.get('item_reports', queryParam: param, type: 'json').then(
        (response) {
      if (response.statusCode == 200) {
        setState(() {
          itemReports = response.data['data']
              .map<ItemReport>((data) => ItemReport.fromJson(data,
                  included: response.data['included'] ?? []))
              .toList();
          _source?.setModels(itemReports);
        });
        _source?.setShowLoading(false);
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    });
  }

  void _select() {
    Navigator.of(context).pop(selectedItem);
  }
}
