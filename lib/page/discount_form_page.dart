import 'package:fe_pos/model/customer_group.dart';
import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/model/discount.dart';

import 'package:provider/provider.dart';

class DiscountFormPage extends StatefulWidget {
  final Discount discount;
  const DiscountFormPage({super.key, required this.discount});

  @override
  State<DiscountFormPage> createState() => _DiscountFormPageState();
}

class _DiscountFormPageState extends State<DiscountFormPage>
    with
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Discount get discount => widget.discount;
  late final TextEditingController _discount2Controller;
  late final TextEditingController _discount3Controller;
  late final TextEditingController _discount4Controller;
  late final TextEditingController _codeController;
  late final TabController _tabController;
  late PlutoGridStateManager _source;
  late final Server server;
  dynamic discount1;
  Percentage? discount2;
  Percentage? discount3;
  Percentage? discount4;

  late final List<TableColumn> _columns = [];
  late FocusNode _focusNode;
  final _whitelistColumns = [
    'item_code',
    'item_name',
    'item_type_name',
    'brand_name',
    'supplier_code',
    'stock_left',
    'warehouse_stock',
    'store_stock',
    'cogs',
    'margin',
    'limit_profit_discount',
    'sell_price',
  ];
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    final setting = context.read<Setting>();
    setting.tableColumn('itemReport').forEach((TableColumn tableColumn) {
      if (_whitelistColumns.contains(tableColumn.name)) {
        _columns.add(tableColumn);
      }
    });
    _columns.addAll([
      TableColumn(
        clientWidth: 180,
        type: TableColumnType.money,
        name: 'discount_amount',
        humanizeName: 'Jumlah Diskon',
        renderBody: (PlutoColumnRendererContext rendererContext) {
          Money sellPrice =
              Money(rendererContext.row.cells['sell_price']?.value ?? 0);
          String value = '';
          if (discount.calculationType == DiscountCalculationType.nominal) {
            value = discount.discount1Nominal.format();
          } else if (discount.calculationType ==
              DiscountCalculationType.percentage) {
            value = _calculateChanellingDiscount(sellPrice, discount).format();
          } else if (discount.calculationType ==
              DiscountCalculationType.specialPrice) {
            value = (sellPrice - discount.discount1Nominal).format();
          }
          return Align(
              alignment: Alignment.topRight, child: SelectableText(value));
        },
      ),
      TableColumn(
        clientWidth: 180,
        type: TableColumnType.money,
        name: 'sell_price_after_discount',
        humanizeName: 'Harga Setelah Diskon',
        renderBody: (PlutoColumnRendererContext rendererContext) {
          Money sellPrice =
              Money(rendererContext.row.cells['sell_price']?.value ?? 0);
          String value = '';
          if (discount.calculationType == DiscountCalculationType.nominal) {
            value = (sellPrice - discount.discount1Nominal).format();
          } else if (discount.calculationType ==
              DiscountCalculationType.percentage) {
            value =
                (sellPrice - _calculateChanellingDiscount(sellPrice, discount))
                    .format();
          } else if (discount.calculationType ==
              DiscountCalculationType.specialPrice) {
            value = discount.discount1Nominal.format();
          }
          return Align(
              alignment: Alignment.topRight, child: SelectableText(value));
        },
      ),
      TableColumn(
        clientWidth: 180,
        name: 'profit_after_discount',
        type: TableColumnType.money,
        humanizeName: 'Jumlah Profit Setelah Diskon',
        renderBody: (PlutoColumnRendererContext rendererContext) {
          Money sellPrice =
              Money(rendererContext.row.cells['sell_price']?.value ?? 0);
          Money cogs = Money(rendererContext.row.cells['cogs']?.value ?? 0);
          Money newPrice = sellPrice;
          if (discount.calculationType == DiscountCalculationType.nominal) {
            newPrice = sellPrice - discount.discount1Nominal;
          } else if (discount.calculationType ==
              DiscountCalculationType.percentage) {
            newPrice =
                sellPrice - _calculateChanellingDiscount(sellPrice, discount);
          } else if (discount.calculationType ==
              DiscountCalculationType.specialPrice) {
            newPrice = discount.discount1Nominal;
          }
          return Align(
              alignment: Alignment.topRight,
              child: SelectableText((newPrice - cogs).format()));
        },
      ),
      TableColumn(
        clientWidth: 180,
        name: 'profit_margin_after_discount',
        type: TableColumnType.percentage,
        humanizeName: 'Profit Setelah Diskon(%)',
        renderBody: (PlutoColumnRendererContext rendererContext) {
          Money sellPrice =
              Money(rendererContext.row.cells['sell_price']?.value ?? 0);
          Money cogs = Money(rendererContext.row.cells['cogs']?.value ?? 0);
          Money newPrice = sellPrice;
          if (discount.calculationType == DiscountCalculationType.nominal) {
            newPrice = sellPrice - discount.discount1Nominal;
          } else if (discount.calculationType ==
              DiscountCalculationType.percentage) {
            newPrice =
                sellPrice - _calculateChanellingDiscount(sellPrice, discount);
          } else if (discount.calculationType ==
              DiscountCalculationType.specialPrice) {
            newPrice = discount.discount1Nominal;
          }
          final margin = _marginOf(newPrice, cogs);
          return Align(
              alignment: Alignment.topRight,
              child: SelectableText(margin.format()));
        },
      ),
    ]);
    server = context.read<Server>();
    _codeController = TextEditingController(text: discount.code);
    _discount2Controller =
        TextEditingController(text: discount.discount2.toString());
    _discount3Controller =
        TextEditingController(text: discount.discount3.toString());
    _discount4Controller =
        TextEditingController(text: discount.discount4.toString());
    flash = Flash();
    _focusNode = FocusNode();
    super.initState();
    Future.delayed(Duration.zero, () {
      if (discount.isNewRecord) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      } else {
        fetchDiscount();
      }
    });
  }

  void refreshTable() {
    _source.setShowLoading(true);
    setState(() {
      discount1 = discount.discount1;
      discount2 = discount.discount2;
      discount3 = discount.discount3;
      discount4 = discount.discount4;
    });

    Map<String, dynamic> param = {
      'page[page]': '1',
      'page[limit]': '1000',
      'report_type': 'json',
      'sort': 'item_code',
    };
    if (discount.items.isNotEmpty) {
      param['filter[item_code][eq]'] =
          discount.items.map((line) => line.code).toList().join(',');
    }
    if (discount.suppliers.isNotEmpty) {
      param['filter[supplier_code][eq]'] =
          discount.suppliers.map((line) => line.code).toList().join(',');
    }
    if (discount.itemTypes.isNotEmpty) {
      param['filter[item_type_name][eq]'] =
          discount.itemTypes.map((line) => line.name).toList().join(',');
    }
    if (discount.brands.isNotEmpty) {
      param['filter[brand_name][eq]'] =
          discount.brands.map((line) => line.name).toList().join(',');
    }
    if (discount.blacklistItems.isNotEmpty) {
      param['filter[item_code][not]'] =
          discount.blacklistItems.map((line) => line.code).toList().join(',');
    }
    if (discount.blacklistSuppliers.isNotEmpty) {
      param['filter[supplier_code][not]'] = discount.blacklistSuppliers
          .map((line) => line.code)
          .toList()
          .join(',');
    }
    if (discount.blacklistItemTypes.isNotEmpty) {
      param['filter[item_type_name][not]'] = discount.blacklistItemTypes
          .map((line) => line.name)
          .toList()
          .join(',');
    }
    if (discount.blacklistBrands.isNotEmpty) {
      param['filter[brand_name][not]'] =
          discount.blacklistBrands.map((line) => line.name).toList().join(',');
    }
    server.get('item_reports', queryParam: param).then((response) {
      try {
        if (response.statusCode != 200) {
          flash.showBanner(
              messageType: ToastificationType.error,
              title: 'Gagal Refresh Tabel');
        }
        var data = response.data;

        final models = data['data'].map<ItemReport>((row) {
          return ItemReport.fromJson(row, included: data['included'] ?? []);
        }).toList();
        _source.setModels(models, _columns);
      } catch (error, stackTrace) {
        debugPrint(error.toString());
        debugPrint(stackTrace.toString());
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => _source.setShowLoading(false));
  }

  Percentage _marginOf(Money sellPrice, Money buyPrice) {
    var margin = (sellPrice.value / buyPrice.value) - 1;
    return Percentage(margin);
  }

  Money _calculateChanellingDiscount(Money sellPrice, Discount discount) {
    Money result = sellPrice;
    Money newSellPrice = sellPrice;
    result = result * discount.discount1Percentage.value;
    if (discount.discount2 == null) {
      return result;
    }
    newSellPrice = sellPrice - result;
    result += newSellPrice * discount.discount2!.value;
    if (discount.discount3 == null) {
      return result;
    }
    newSellPrice = sellPrice - result;
    result += newSellPrice * discount.discount3!.value;
    if (discount.discount4 == null) {
      return result;
    }
    newSellPrice = sellPrice - result;
    result += newSellPrice * discount.discount4!.value;
    return result;
  }

  void fetchDiscount() {
    showLoadingPopup();
    server.get('/discounts/${discount.id}', queryParam: {
      'include':
          'discount_items,discount_suppliers,discount_item_types,discount_brands,discount_brands.brand,discount_item_types.item_type,discount_suppliers.supplier,discount_items.item,customer_group'
    }).then((response) {
      if (response.statusCode == 200) {
        var json = response.data['data'];
        setState(() {
          Discount.fromJson(json,
              included: response.data['included'], model: discount);
          _codeController.text = discount.code;
        });
        _focusNode.requestFocus();
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }

  void _submit() async {
    final server = context.read<Server>();
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
    Future request;
    if (discount.id == null) {
      request = server.post('discounts', body: body);
    } else {
      request = server.put('discounts/${discount.id}', body: body);
    }
    showLoadingPopup();
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        if (discount.id == null) {
          setState(() {
            discount.id = int.tryParse(data['id']);
            discount.code = data['attributes']['code'];
            var tabManager = context.read<TabManager>();
            tabManager.changeTabHeader(
                widget, 'Edit discount ${discount.code}');
          });
        }

        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  void downloadDiscountItems() {
    showLoadingPopup();
    server.get('discounts/${discount.id}/download_items', type: 'xlsx').then(
        (response) async {
      if (response.statusCode != 200) {
        flash.showBanner(
            title: 'Gagal Download',
            description: 'Gagal Download discount item ${discount.code}',
            messageType: ToastificationType.error);
      }
      String filename = response.headers.value('content-disposition') ?? '';
      if (filename.isEmpty) {
        return;
      }
      filename = filename.substring(
          filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
      var downloader = const FileSaver();
      downloader.download(filename, response.data, 'xlsx',
          onSuccess: (String path) {
        flash.showBanner(
            messageType: ToastificationType.success,
            title: 'Sukses download',
            description: 'sukses disimpan di $path');
      });
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints.loose(const Size.fromWidth(400)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Visibility(
                      visible: discount.id != null,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                              onPressed: () =>
                                  fetchHistoryByRecord('Discount', discount.id),
                              label: const Text('Riwayat'),
                              icon: const Icon(Icons.history)),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton.icon(
                              onPressed: () => downloadDiscountItems(),
                              label: const Text('Download'),
                              icon: const Icon(Icons.download_rounded)),
                        ],
                      ),
                    ),
                    const Divider(),
                    TextFormField(
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        label: Text('kode diskon : ', style: labelStyle),
                        border: OutlineInputBorder(),
                      ),
                      controller: _codeController,
                      onChanged: (value) {
                        discount.code = value;
                      },
                      onSaved: (value) {
                        discount.code = value?.trim() ?? '';
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: NumberFormField<int>(
                        hintText:
                            'level paling tinggi yang akan dipakai jika antar aturan diskon konflik',
                        label: const Text(
                          'Level Diskon',
                          style: labelStyle,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'tidak valid';
                          } else if (value < 1) {
                            return 'tidak boleh lebih kecil dari 1';
                          }
                          return null;
                        },
                        onChanged: ((value) => discount.weight = value ?? 0),
                        initialValue: discount.weight,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              TabBar(
                  controller: _tabController,
                  onTap: (idx) {
                    if (idx == 2) {
                      refreshTable();
                    }
                  },
                  tabs: const [
                    Tab(
                      child: Text('Filter Diskon'),
                    ),
                    Tab(
                      child: Text('Periode Aktif diskon'),
                    ),
                    Tab(
                      child: Text('Kalkulasi Diskon'),
                    ),
                  ]),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: SizedBox(
                  height: 950,
                  child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<ItemType>(
                                    selecteds: discount.itemTypes,
                                    key: const ValueKey('itemTypeSelect'),
                                    path: '/item_types',
                                    attributeKey: 'jenis',
                                    label: const Text(
                                      'Jenis/Departemen :',
                                      style: labelStyle,
                                    ),
                                    textOnSelected: (itemType) => itemType.name,
                                    textOnSearch: (itemType) =>
                                        '${itemType.name} - ${itemType.description}',
                                    converter: ItemType.fromJson,
                                    onChanged: (option) {
                                      discount.itemTypes = option;
                                    },
                                    validator: (value) {
                                      if (discount.items.isEmpty &&
                                          discount.itemTypes.isEmpty &&
                                          discount.brands.isEmpty &&
                                          discount.suppliers.isEmpty) {
                                        return 'salah satu filter harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Supplier>(
                                    key: const ValueKey('supplierSelect'),
                                    selecteds: discount.suppliers,
                                    path: '/suppliers',
                                    attributeKey: 'kode',
                                    textOnSelected: (supplier) => supplier.code,
                                    textOnSearch: (supplier) =>
                                        '${supplier.code} - ${supplier.name}',
                                    converter: Supplier.fromJson,
                                    label: const Text(
                                      'Supplier:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.suppliers = option;
                                    },
                                    validator: (value) {
                                      if (discount.items.isEmpty &&
                                          discount.itemTypes.isEmpty &&
                                          discount.brands.isEmpty &&
                                          discount.suppliers.isEmpty) {
                                        return 'salah satu filter harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Brand>(
                                    key: const ValueKey('brandSelect'),
                                    selecteds: discount.brands,
                                    path: '/brands',
                                    attributeKey: 'merek',
                                    textOnSearch: (brand) => brand.name,
                                    converter: Brand.fromJson,
                                    label: const Text(
                                      'Merek:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.brands = option;
                                    },
                                    validator: (value) {
                                      if (discount.items.isEmpty &&
                                          discount.itemTypes.isEmpty &&
                                          discount.brands.isEmpty &&
                                          discount.suppliers.isEmpty) {
                                        return 'salah satu filter harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Item>(
                                    key: const ValueKey('itemSelect'),
                                    selecteds: discount.items,
                                    path: '/items',
                                    attributeKey: 'namaitem',
                                    textOnSelected: (item) => item.code,
                                    textOnSearch: (item) =>
                                        "${item.code} - ${item.name}",
                                    converter: Item.fromJson,
                                    label: const Text(
                                      'Item:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.items = option;
                                    },
                                    validator: (value) {
                                      if (discount.items.isEmpty &&
                                          discount.itemTypes.isEmpty &&
                                          discount.brands.isEmpty &&
                                          discount.suppliers.isEmpty) {
                                        return 'salah satu filter harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<ItemType>(
                                    key: const ValueKey(
                                        'blacklistItemTypeSelect'),
                                    selecteds: discount.blacklistItemTypes,
                                    path: '/item_types',
                                    attributeKey: 'jenis',
                                    textOnSelected: (itemType) => itemType.name,
                                    textOnSearch: (itemType) =>
                                        '${itemType.name} - ${itemType.description}',
                                    converter: ItemType.fromJson,
                                    label: const Text(
                                      'Blacklist Jenis/Departemen :',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.blacklistItemTypes = option;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Supplier>(
                                    key: const ValueKey(
                                        'blacklistSupplierSelect'),
                                    selecteds: discount.blacklistSuppliers,
                                    path: '/suppliers',
                                    attributeKey: 'kode',
                                    textOnSelected: (supplier) => supplier.code,
                                    textOnSearch: (supplier) =>
                                        '${supplier.code} - ${supplier.name}',
                                    converter: Supplier.fromJson,
                                    label: const Text(
                                      'Blacklist Supplier:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.blacklistSuppliers = option;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Brand>(
                                    key: const ValueKey('blacklistBrandSelect'),
                                    selecteds: discount.blacklistBrands,
                                    path: '/brands',
                                    attributeKey: 'merek',
                                    textOnSearch: (brand) => brand.name,
                                    converter: Brand.fromJson,
                                    label: const Text(
                                      'Blacklist Merek:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.blacklistBrands = option;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdownMultiple<Item>(
                                    key: const ValueKey('blacklistItemSelect'),
                                    selecteds: discount.blacklistItems,
                                    path: '/items',
                                    attributeKey: 'namaitem',
                                    textOnSelected: (item) => item.code,
                                    textOnSearch: (item) =>
                                        "${item.code} - ${item.name}",
                                    converter: Item.fromJson,
                                    label: const Text(
                                      'Blacklist Item:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.blacklistItems = option;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 400,
                                  child: AsyncDropdown<CustomerGroup>(
                                    key: const ValueKey('customerGroupCode'),
                                    selected: discount.customerGroup,
                                    path: '/customer_groups',
                                    attributeKey: 'grup',
                                    textOnSelected: (customerGroup) =>
                                        customerGroup.code,
                                    textOnSearch: (customerGroup) =>
                                        "${customerGroup.code} - ${customerGroup.name}",
                                    converter: CustomerGroup.fromJson,
                                    label: const Text(
                                      'Grup Pelanggan:',
                                      style: labelStyle,
                                    ),
                                    onChanged: (option) {
                                      discount.customerGroup = option;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    width: 400,
                                    child: DateRangeFormField(
                                      initialDateRange: DateTimeRange(
                                          start: discount.startTime,
                                          end: discount.endTime),
                                      label: const Text(
                                        'Tanggal Aktif',
                                        style: labelStyle,
                                      ),
                                      icon: const Icon(
                                          Icons.calendar_today_outlined),
                                      onChanged: ((DateTimeRange? range) {
                                        if (range == null) {
                                          return;
                                        }
                                        discount.startTime = range.start;
                                        discount.endTime = range.end;
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Text(
                                  'Aturan Aktif Diskon',
                                  style: labelStyle,
                                ),
                                Wrap(
                                  children: [
                                    Radio<DiscountType>(
                                      value: DiscountType.period,
                                      groupValue: discount.discountType,
                                      onChanged: (value) {
                                        setState(() {
                                          discount.discountType =
                                              value ?? DiscountType.period;
                                        });
                                      },
                                    ),
                                    Text(DiscountType.period.humanize()),
                                    Radio<DiscountType>(
                                      value: DiscountType.dayOfWeek,
                                      groupValue: discount.discountType,
                                      onChanged: (value) {
                                        setState(() {
                                          discount.discountType =
                                              value ?? DiscountType.dayOfWeek;
                                        });
                                      },
                                    ),
                                    Text(DiscountType.dayOfWeek.humanize()),
                                  ],
                                ),
                                Visibility(
                                  visible: discount.discountType ==
                                      DiscountType.dayOfWeek,
                                  child: Wrap(
                                    children: [
                                      CheckboxListTile(
                                        title: const Text("Senin"),
                                        value: discount.week1,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week1 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Selasa"),
                                        value: discount.week2,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week2 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Rabu"),
                                        value: discount.week3,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week3 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Kamis"),
                                        value: discount.week4,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week4 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Jumat"),
                                        value: discount.week5,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week5 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Sabtu"),
                                        value: discount.week6,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week6 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Minggu"),
                                        value: discount.week7,
                                        onChanged: (newValue) {
                                          setState(() {
                                            discount.week7 = newValue ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 400,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tipe Kalkulasi:',
                                        style: labelStyle,
                                      ),
                                      Wrap(
                                        children: [
                                          Radio<DiscountCalculationType>(
                                            value: DiscountCalculationType
                                                .percentage,
                                            groupValue:
                                                discount.calculationType,
                                            onChanged: (value) {
                                              setState(() {
                                                discount.calculationType =
                                                    value ??
                                                        DiscountCalculationType
                                                            .percentage;
                                                if (discount.discount1
                                                    is Money) {
                                                  discount.discount1 = discount
                                                      .discount1Percentage;
                                                }
                                                _discount2Controller.text =
                                                    discount.discount2Nominal
                                                        .toString();
                                                _discount3Controller.text =
                                                    discount.discount3Nominal
                                                        .toString();
                                                _discount4Controller.text =
                                                    discount.discount4Nominal
                                                        .toString();
                                              });
                                            },
                                          ),
                                          Text(DiscountCalculationType
                                              .percentage
                                              .humanize()),
                                          Radio<DiscountCalculationType>(
                                            value:
                                                DiscountCalculationType.nominal,
                                            groupValue:
                                                discount.calculationType,
                                            onChanged: (value) {
                                              setState(() {
                                                discount.calculationType =
                                                    value ??
                                                        DiscountCalculationType
                                                            .nominal;
                                                if (discount.discount1
                                                    is Percentage) {
                                                  discount.discount1 =
                                                      discount.discount1Nominal;
                                                }
                                                discount.discount2 =
                                                    const Percentage(0);
                                                discount.discount3 =
                                                    discount.discount2;
                                                discount.discount4 =
                                                    discount.discount2;
                                                _discount2Controller.text =
                                                    discount.discount2Nominal
                                                        .toString();
                                                _discount3Controller.text =
                                                    discount.discount3Nominal
                                                        .toString();
                                                _discount4Controller.text =
                                                    discount.discount4Nominal
                                                        .toString();
                                              });
                                            },
                                          ),
                                          Text(DiscountCalculationType.nominal
                                              .humanize()),
                                          Radio<DiscountCalculationType>(
                                            value: DiscountCalculationType
                                                .specialPrice,
                                            groupValue:
                                                discount.calculationType,
                                            onChanged: (value) {
                                              setState(() {
                                                discount.calculationType =
                                                    value ??
                                                        DiscountCalculationType
                                                            .specialPrice;
                                                if (discount.discount1
                                                    is Percentage) {
                                                  discount.discount1 =
                                                      discount.discount1Nominal;
                                                }
                                                discount.discount2 =
                                                    const Percentage(0);

                                                discount.discount3 =
                                                    discount.discount2;
                                                discount.discount4 =
                                                    discount.discount2;
                                                _discount2Controller.text =
                                                    discount.discount2Nominal
                                                        .toString();
                                                _discount3Controller.text =
                                                    discount.discount3Nominal
                                                        .toString();
                                                _discount4Controller.text =
                                                    discount.discount4Nominal
                                                        .toString();
                                              });
                                            },
                                          ),
                                          Text(DiscountCalculationType
                                              .specialPrice
                                              .humanize()),
                                        ],
                                      ),
                                      if (discount.calculationType ==
                                          DiscountCalculationType.percentage)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: PercentageFormField(
                                            label: const Text(
                                              'Diskon 1',
                                              style: labelStyle,
                                            ),
                                            validator: (value) {
                                              if (value == null) {
                                                return 'tidak valid';
                                              }
                                              if (value >= 100 || value < 0) {
                                                return 'range valid antara 0 - 100';
                                              }
                                              return null;
                                            },
                                            onChanged: ((value) {
                                              discount.discount1 = value;
                                            }),
                                            initialValue:
                                                discount.discount1Percentage,
                                          ),
                                        ),
                                      if (discount.calculationType !=
                                          DiscountCalculationType.percentage)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: MoneyFormField(
                                            label: const Text(
                                              'Diskon 1',
                                              style: labelStyle,
                                            ),
                                            validator: (value) {
                                              if (value == null) {
                                                return 'tidak valid';
                                              }
                                              if (value <= 0) {
                                                return 'harus lebih besar dari 0';
                                              }
                                              return null;
                                            },
                                            onChanged: ((value) {
                                              discount.discount1 = value;
                                            }),
                                            initialValue:
                                                discount.discount1Nominal,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: PercentageFormField(
                                          controller: _discount2Controller,
                                          readOnly: discount.calculationType ==
                                              DiscountCalculationType.nominal,
                                          label: const Text(
                                            'Diskon 2',
                                            style: labelStyle,
                                          ),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'tidak valid';
                                            } else if (value >= 100 ||
                                                value < 0) {
                                              return 'range valid antara 0 - 100';
                                            }
                                            return null;
                                          },
                                          onChanged: ((value) =>
                                              discount.discount2 = value),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: PercentageFormField(
                                          readOnly: discount.calculationType ==
                                              DiscountCalculationType.nominal,
                                          controller: _discount3Controller,
                                          label: const Text(
                                            'Diskon 3',
                                            style: labelStyle,
                                          ),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'tidak valid';
                                            } else if (value >= 100 ||
                                                value < 0) {
                                              return 'range valid antara 0 - 100';
                                            }
                                            return null;
                                          },
                                          onChanged: ((value) =>
                                              discount.discount3 = value),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: PercentageFormField(
                                          readOnly: discount.calculationType ==
                                              DiscountCalculationType.nominal,
                                          controller: _discount4Controller,
                                          label: const Text(
                                            'Diskon 4',
                                            style: labelStyle,
                                          ),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'tidak valid';
                                            } else if (value >= 100 ||
                                                value < 0) {
                                              return 'range valid antara 0 - 100';
                                            }
                                            return null;
                                          },
                                          onChanged: ((value) =>
                                              discount.discount4 = value),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                        text: TextSpan(
                                            text: 'Preview Item ',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18),
                                            children:
                                                discountSummaryPreview())),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: ElevatedButton.icon(
                                          onPressed: refreshTable,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Refresh Table')),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  height: 550,
                                  child: SyncDataTable<ItemReport>(
                                    columns: _columns,
                                    fixedLeftColumns: 2,
                                    onLoaded: (stateManager) =>
                                        _source = stateManager,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _submit();
                      }
                    },
                    child: const Text('submit')),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> discountSummaryPreview() {
    List<TextSpan> textArr = [];
    const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.black);

    textArr.add(const TextSpan(text: 'Diskon1: '));
    if (discount1 is Percentage) {
      textArr.add(TextSpan(
        text: discount1.format(),
        style: style,
      ));
    } else if (discount1 is Money) {
      textArr.add(TextSpan(
        text: discount1.format(),
        style: style,
      ));
    }
    if (discount2 != null) {
      textArr.add(const TextSpan(text: ', Diskon2: '));
      textArr.add(TextSpan(
        text: discount2!.format(),
        style: style,
      ));
    }
    if (discount3 != null) {
      textArr.add(const TextSpan(text: ', Diskon3: '));
      textArr.add(TextSpan(
        text: discount3!.format(),
        style: style,
      ));
    }
    if (discount4 != null) {
      textArr.add(const TextSpan(text: ', Diskon4: '));
      textArr.add(TextSpan(
        text: discount4!.format(),
        style: style,
      ));
    }
    return textArr;
  }
}
