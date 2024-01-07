import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:fe_pos/widget/dropdown_remote_connection.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:fe_pos/model/discount.dart';

import 'package:provider/provider.dart';

class DiscountFormPage extends StatefulWidget {
  final Discount discount;
  const DiscountFormPage({super.key, required this.discount});

  @override
  State<DiscountFormPage> createState() => _DiscountFormPageState();
}

class _DiscountFormPageState extends State<DiscountFormPage> {
  late final BsSelectBoxController _brandSelectWidget;

  late final BsSelectBoxController _supplierSelectWidget;

  late final BsSelectBoxController _itemTypeSelectWidget;

  late final BsSelectBoxController _itemSelectWidget;
  late DropdownRemoteConnection connection;
  late Flash flash;
  final _formKey = GlobalKey<FormState>();
  Discount get discount => widget.discount;
  @override
  void initState() {
    var sessionState = context.read<SessionState>();
    connection = DropdownRemoteConnection(sessionState.server, context);
    _brandSelectWidget = BsSelectBoxController(
        multiple: false,
        processing: true,
        selected: discount.brandName != null
            ? <BsSelectBoxOption>[
                BsSelectBoxOption(
                    value: discount.brandName,
                    text: Text(discount.brandName as String))
              ]
            : null);

    _supplierSelectWidget = BsSelectBoxController(
        multiple: false,
        processing: true,
        selected: discount.supplierCode != null
            ? <BsSelectBoxOption>[
                BsSelectBoxOption(
                    value: discount.supplierCode,
                    text: Text(discount.supplierCode as String))
              ]
            : null);

    _itemTypeSelectWidget = BsSelectBoxController(
        multiple: false,
        processing: true,
        selected: discount.itemType != null
            ? <BsSelectBoxOption>[
                BsSelectBoxOption(
                    value: discount.itemType,
                    text: Text(discount.itemType as String))
              ]
            : null);

    _itemSelectWidget = BsSelectBoxController(
        multiple: false,
        processing: true,
        selected: discount.itemCode != null
            ? <BsSelectBoxOption>[
                BsSelectBoxOption(
                    value: discount.itemCode,
                    text: Text(discount.itemCode as String))
              ]
            : null);
    flash = Flash(context);
    super.initState();
  }

  List<BsSelectBoxOption> convertToOptions(List list) {
    return list
        .map(((row) => BsSelectBoxOption(
            value: row['id'],
            text: Text(row['name'].substring(
                0, row['name'].length < 16 ? row['name'].length : 16)))))
        .toList();
  }

  void _submit() async {
    var sessionState = context.read<SessionState>();
    var server = sessionState.server;
    Map body = {'discount': discount};
    Future request;
    if (discount.id == null) {
      request = server.post('discounts', body: body);
    } else {
      request = server.put('discounts/${discount.code}', body: body);
    }
    request.then((response) {
      if (response.statusCode == 200) {
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
      server.defaultResponse(context: context, error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    var labelStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                  Row(
                    children: [
                      Text('kode diskon : ', style: labelStyle),
                      Text(discount.code),
                    ],
                  ),
                  Text(
                    'Jenis/Departemen :',
                    style: labelStyle,
                  ),
                  Flexible(
                      child: BsSelectBox(
                    key: const ValueKey('itemTypeSelect'),
                    searchable: true,
                    controller: _itemTypeSelectWidget,
                    onChange: (option) {
                      discount.itemType = option.getValueAsString();
                    },
                    serverSide: (params) async {
                      var list = await connection.getData('/item_types',
                          query: params['searchValue'].toString());
                      return BsSelectBoxResponse(
                          options: convertToOptions(list));
                    },
                  )),
                  Text(
                    'Item:',
                    style: labelStyle,
                  ),
                  Flexible(
                      child: BsSelectBox(
                    key: const ValueKey('itemSelect'),
                    searchable: true,
                    onChange: (option) {
                      discount.itemCode = option.getValueAsString();
                    },
                    controller: _itemSelectWidget,
                    serverSide: (params) async {
                      var list = await connection.getData('/items',
                          query: params['searchValue'].toString());
                      return BsSelectBoxResponse(
                          options: convertToOptions(list));
                    },
                  )),
                  Text(
                    'Supplier:',
                    style: labelStyle,
                  ),
                  Flexible(
                      child: BsSelectBox(
                    key: const ValueKey('supplierSelect'),
                    searchable: true,
                    onChange: (option) {
                      discount.supplierCode = option.getValueAsString();
                    },
                    controller: _supplierSelectWidget,
                    serverSide: (params) async {
                      var list = await connection.getData('/suppliers',
                          query: params['searchValue'].toString());
                      return BsSelectBoxResponse(
                          options: convertToOptions(list));
                    },
                  )),
                  Text(
                    'Merek:',
                    style: labelStyle,
                  ),
                  Flexible(
                      child: BsSelectBox(
                    key: const ValueKey('brandSelect'),
                    searchable: true,
                    onChange: (option) {
                      discount.brandName = option.getValueAsString();
                    },
                    controller: _brandSelectWidget,
                    serverSide: (params) async {
                      var list = await connection.getData('/brands',
                          query: params['searchValue'].toString());
                      return BsSelectBoxResponse(
                          options: convertToOptions(list));
                    },
                  )),
                  Flexible(
                      child: TextFormField(
                    decoration: InputDecoration(
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
                      } else if (valDouble >= 100) {
                        return 'tidak boleh lebih dari 100';
                      }
                      return null;
                    },
                    onChanged: ((value) => discount.discount1 =
                        Percentage.tryParse(value) ?? const Percentage(0.0)),
                    initialValue: discount.discount1.toString(),
                  )),
                  Flexible(
                      child: TextFormField(
                    decoration: InputDecoration(
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
                      } else if (valDouble >= 100) {
                        return 'tidak boleh lebih dari 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount2 = Percentage.tryParse(value)),
                    initialValue: discount.discount2.toString(),
                  )),
                  Flexible(
                      child: TextFormField(
                    decoration: InputDecoration(
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
                      } else if (valDouble >= 100) {
                        return 'tidak boleh lebih dari 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount3 = Percentage.tryParse(value)),
                    initialValue: discount.discount3.toString(),
                  )),
                  Flexible(
                      child: TextFormField(
                    decoration: InputDecoration(
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
                      } else if (valDouble >= 100) {
                        return 'tidak boleh lebih dari 100';
                      }
                      return null;
                    },
                    onChanged: ((value) =>
                        discount.discount4 = Percentage.tryParse(value)),
                    initialValue: discount.discount4.toString(),
                  )),
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: DateRangePicker(
                      startDate: discount.startTime,
                      endDate: discount.endTime,
                      label: Text(
                        'Tanggal Aktif',
                        style: labelStyle,
                      ),
                      icon: const Icon(Icons.calendar_today_outlined),
                      onChanged: ((DateTimeRange range) {
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
