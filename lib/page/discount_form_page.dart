import 'package:fe_pos/tool/flash.dart';
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
    with AutomaticKeepAliveClientMixin {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Discount get discount => widget.discount;
  late final TextEditingController _discount2Controller;
  late final TextEditingController _discount3Controller;
  late final TextEditingController _discount4Controller;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _discount2Controller =
        TextEditingController(text: discount.discount2Nominal.toString());
    _discount3Controller =
        TextEditingController(text: discount.discount3Nominal.toString());
    _discount4Controller =
        TextEditingController(text: discount.discount4Nominal.toString());

    flash = Flash(context);
    super.initState();
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {'discount': discount};
    Future request;
    if (discount.id == null) {
      request = server.post('discounts', body: body);
    } else {
      request = server.put('discounts/${discount.id}', body: body);
    }
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
    });
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
                  TextFormField(
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
                      discount.code = value ?? '';
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  AsyncDropdown(
                    selected: discount.itemType == null
                        ? null
                        : DropdownResult(
                            value: discount.itemType,
                            text: discount.itemType ?? ''),
                    key: const ValueKey('itemTypeSelect'),
                    path: '/item_types',
                    attributeKey: 'jenis',
                    label: const Text(
                      'Jenis/Departemen :',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.itemType = option?.value;
                    },
                    validator: (value) {
                      if (discount.itemCode == null &&
                          discount.itemType == null &&
                          discount.brandName == null &&
                          discount.supplierCode == null) {
                        return 'salah satu filter harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('supplierSelect'),
                    selected: discount.supplierCode == null
                        ? null
                        : DropdownResult(
                            value: discount.supplierCode,
                            text: discount.supplierCode ?? ''),
                    path: '/suppliers',
                    attributeKey: 'kode',
                    label: const Text(
                      'Supplier:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.supplierCode = option?.value;
                    },
                    validator: (value) {
                      if (discount.itemCode == null &&
                          discount.itemType == null &&
                          discount.brandName == null &&
                          discount.supplierCode == null) {
                        return 'salah satu filter harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('brandSelect'),
                    selected: discount.brandName == null
                        ? null
                        : DropdownResult(
                            value: discount.brandName,
                            text: discount.brandName ?? ''),
                    path: '/brands',
                    attributeKey: 'merek',
                    label: const Text(
                      'Merek:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.brandName = option?.value;
                    },
                    validator: (value) {
                      if (discount.itemCode == null &&
                          discount.itemType == null &&
                          discount.brandName == null &&
                          discount.supplierCode == null) {
                        return 'salah satu filter harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('itemSelect'),
                    selected: discount.itemCode == null
                        ? null
                        : DropdownResult(
                            value: discount.itemCode,
                            text: discount.itemCode ?? ''),
                    path: '/items',
                    attributeKey: 'namaitem',
                    label: const Text(
                      'Item:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.itemCode = option?.value;
                    },
                    validator: (value) {
                      if (discount.itemCode == null &&
                          discount.itemType == null &&
                          discount.brandName == null &&
                          discount.supplierCode == null) {
                        return 'salah satu filter harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('blacklistItemTypeSelect'),
                    selected: discount.blacklistItemType == null
                        ? null
                        : DropdownResult(
                            value: discount.blacklistItemType,
                            text: discount.blacklistItemType ?? ''),
                    path: '/item_types',
                    attributeKey: 'jenis',
                    label: const Text(
                      'Blacklist Jenis/Departemen :',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.blacklistItemType = option?.value;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('blacklistSupplierSelect'),
                    selected: discount.blacklistSupplierCode == null
                        ? null
                        : DropdownResult(
                            value: discount.blacklistSupplierCode,
                            text: discount.blacklistSupplierCode ?? ''),
                    path: '/suppliers',
                    attributeKey: 'kode',
                    label: const Text(
                      'Blacklist Supplier:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.blacklistSupplierCode = option?.value;
                    },
                  ),
                  const SizedBox(height: 10),
                  AsyncDropdown(
                    key: const ValueKey('blacklistBrandSelect'),
                    selected: discount.blacklistBrandName == null
                        ? null
                        : DropdownResult(
                            value: discount.blacklistBrandName,
                            text: discount.blacklistBrandName ?? ''),
                    path: '/brands',
                    attributeKey: 'merek',
                    label: const Text(
                      'Blacklist Merek:',
                      style: labelStyle,
                    ),
                    onChanged: (option) {
                      discount.blacklistBrandName = option?.value;
                    },
                  ),
                  const Text(
                    'Tipe Kalkulasi:',
                    style: labelStyle,
                  ),
                  Row(
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
                      const Text('percentage'),
                      Radio<DiscountCalculationType>(
                        value: DiscountCalculationType.nominal,
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
                            discount.discount2 = const Percentage(0);

                            discount.discount3 = discount.discount2;
                            discount.discount4 = discount.discount2;
                          });
                        },
                      ),
                      const Text('nominal'),
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
                            flash.show(const Text('Loading'), MessageType.info);
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
