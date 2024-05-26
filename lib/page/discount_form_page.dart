import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
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
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Discount get discount => widget.discount;
  late final TextEditingController _discount2Controller;
  late final TextEditingController _discount3Controller;
  late final TextEditingController _discount4Controller;
  late final Server server;
  late FocusNode _focusNode;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    server = context.read<Server>();
    _discount2Controller =
        TextEditingController(text: discount.discount2Nominal.toString());
    _discount3Controller =
        TextEditingController(text: discount.discount3Nominal.toString());
    _discount4Controller =
        TextEditingController(text: discount.discount4Nominal.toString());
    flash = Flash(context);
    _focusNode = FocusNode();
    super.initState();
    Future.delayed(Duration.zero, () {
      if (discount.id == null) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      } else {
        fetchDiscount();
      }
    });
  }

  void fetchDiscount() {
    showLoadingPopup();
    server.get('/discounts/${discount.id}', queryParam: {
      'include':
          'discount_items,discount_suppliers,discount_item_types,discount_brands,discount_brands.brand,discount_item_types.item_type,discount_suppliers.supplier,discount_items.item'
    }).then((response) {
      if (response.statusCode == 200) {
        var json = response.data['data'];
        setState(() {
          Discount.fromJson(json,
              included: response.data['included'], model: discount);
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

        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      server.defaultErrorResponse(context: context, error: error);
    }).whenComplete(() => hideLoadingPopup());
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
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(600)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: discount.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () =>
                            fetchHistoryByRecord('Discount', discount.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  TextFormField(
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      label: Text('kode diskon : ', style: labelStyle),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: discount.code,
                    onChanged: (value) {
                      discount.code = value;
                    },
                    readOnly: discount.id != null,
                    onSaved: (value) {
                      discount.code = value?.trim() ?? '';
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AsyncDropdownMultiple2<ItemType>(
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Supplier>(
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Brand>(
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Item>(
                    key: const ValueKey('itemSelect'),
                    selecteds: discount.items,
                    path: '/items',
                    attributeKey: 'namaitem',
                    textOnSelected: (item) => item.code,
                    textOnSearch: (item) => "${item.code} - ${item.name}",
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<ItemType>(
                    key: const ValueKey('blacklistItemTypeSelect'),
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Supplier>(
                    key: const ValueKey('blacklistSupplierSelect'),
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Brand>(
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
                  const SizedBox(height: 10),
                  AsyncDropdownMultiple2<Item>(
                    key: const ValueKey('blacklistItemSelect'),
                    selecteds: discount.blacklistItems,
                    path: '/items',
                    attributeKey: 'namaitem',
                    textOnSelected: (item) => item.code,
                    textOnSearch: (item) => "${item.code} - ${item.name}",
                    converter: Item.fromJson,
                    label: const Text(
                      'Blacklist Item:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.blacklistItems = option;
                    },
                  ),
                  const Text(
                    'Tipe Kalkulasi:',
                    style: labelStyle,
                  ),
                  Wrap(
                    children: [
                      Radio<DiscountCalculationType>(
                        value: DiscountCalculationType.percentage,
                        groupValue: discount.calculationType,
                        onChanged: (value) {
                          setState(() {
                            discount.calculationType =
                                value ?? DiscountCalculationType.percentage;
                            _discount2Controller.text =
                                discount.discount2Nominal.toString();
                            _discount3Controller.text =
                                discount.discount3Nominal.toString();
                            _discount4Controller.text =
                                discount.discount4Nominal.toString();
                          });
                        },
                      ),
                      Text(DiscountCalculationType.percentage.humanize()),
                      Radio<DiscountCalculationType>(
                        value: DiscountCalculationType.nominal,
                        groupValue: discount.calculationType,
                        onChanged: (value) {
                          setState(() {
                            discount.calculationType =
                                value ?? DiscountCalculationType.nominal;
                            _discount2Controller.text =
                                discount.discount2Nominal.toString();
                            _discount3Controller.text =
                                discount.discount3Nominal.toString();
                            _discount4Controller.text =
                                discount.discount4Nominal.toString();
                            discount.discount2 = const Percentage(0);

                            discount.discount3 = discount.discount2;
                            discount.discount4 = discount.discount2;
                          });
                        },
                      ),
                      Text(DiscountCalculationType.nominal.humanize()),
                    ],
                  ),
                  Flexible(
                      child: TextFormField(
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      hintText:
                          'level paling tinggi yang akan dipakai jika antar aturan diskon konflik',
                      label: Text(
                        'Level Diskon',
                        style: labelStyle,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var valDouble = int.tryParse(value ?? '');
                      if (valDouble == null || valDouble.isNaN) {
                        return 'tidak valid';
                      } else if (valDouble < 1) {
                        return 'tidak boleh lebih kecil dari 1';
                      }
                      return null;
                    },
                    onChanged: ((value) => discount.weight = int.parse(value)),
                    initialValue: discount.weight.toString(),
                  )),
                  Flexible(
                      child: TextFormField(
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      label: Text(
                        'Diskon 1',
                        style: labelStyle,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var valDouble = Percentage.tryParse(value ?? '');
                      if (valDouble == null || valDouble.isNaN) {
                        return 'tidak valid';
                      }
                      if (discount.calculationType ==
                          DiscountCalculationType.percentage) {
                        if (valDouble >= 100 || valDouble < 0) {
                          return 'range valid antara 0 - 100';
                        }
                        return null;
                      } else if (discount.calculationType ==
                          DiscountCalculationType.nominal) {
                        if (valDouble <= 0) {
                          return 'harus lebih besar dari 0';
                        }
                        return null;
                      }
                      return null;
                    },
                    onChanged: ((value) => discount.discount1 =
                        Percentage.tryParse(value) ?? const Percentage(0.0)),
                    initialValue: discount.discount1Nominal.toString(),
                  )),
                  Flexible(
                      child: TextFormField(
                    enableSuggestions: false,
                    controller: _discount2Controller,
                    readOnly: discount.calculationType ==
                        DiscountCalculationType.nominal,
                    decoration: const InputDecoration(
                      label: Text(
                        'Diskon 2',
                        style: labelStyle,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var valDouble = Percentage.tryParse(value ?? '');
                      if (valDouble == null || valDouble.isNaN) {
                        return 'tidak valid';
                      } else if (valDouble >= 100 || valDouble < 0) {
                        return 'range valid antara 0 - 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount2 = Percentage.tryParse(value)),
                  )),
                  Flexible(
                      child: TextFormField(
                    enableSuggestions: false,
                    readOnly: discount.calculationType ==
                        DiscountCalculationType.nominal,
                    controller: _discount3Controller,
                    decoration: const InputDecoration(
                      label: Text(
                        'Diskon 3',
                        style: labelStyle,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var valDouble = Percentage.tryParse(value ?? '');
                      if (valDouble == null || valDouble.isNaN) {
                        return 'tidak valid';
                      } else if (valDouble >= 100 || valDouble < 0) {
                        return 'range valid antara 0 - 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount3 = Percentage.tryParse(value)),
                  )),
                  Flexible(
                      child: TextFormField(
                    enableSuggestions: false,
                    readOnly: discount.calculationType ==
                        DiscountCalculationType.nominal,
                    controller: _discount4Controller,
                    decoration: const InputDecoration(
                      label: Text(
                        'Diskon 4',
                        style: labelStyle,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var valDouble = Percentage.tryParse(value ?? '');
                      if (valDouble == null || valDouble.isNaN) {
                        return 'tidak valid';
                      } else if (valDouble >= 100 || valDouble < 0) {
                        return 'range valid antara 0 - 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount4 = Percentage.tryParse(value)),
                  )),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Tipe Diskon',
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
                    visible: discount.discountType == DiscountType.dayOfWeek,
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
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Selasa"),
                          value: discount.week2,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week2 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Rabu"),
                          value: discount.week3,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week3 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Kamis"),
                          value: discount.week4,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week4 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Jumat"),
                          value: discount.week5,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week5 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Sabtu"),
                          value: discount.week6,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week6 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: const Text("Minggu"),
                          value: discount.week7,
                          onChanged: (newValue) {
                            setState(() {
                              discount.week7 = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: DateRangePicker(
                      initialDateRange: DateTimeRange(
                          start: discount.startTime, end: discount.endTime),
                      label: const Text(
                        'Tanggal Aktif',
                        style: labelStyle,
                      ),
                      icon: const Icon(Icons.calendar_today_outlined),
                      onChanged: ((DateTimeRange? range) {
                        if (range == null) {
                          return;
                        }
                        discount.startTime = range.start;
                        discount.endTime = range.end;
                      }),
                    ),
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
        ),
      ),
    );
  }
}
