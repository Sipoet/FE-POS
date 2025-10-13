import 'package:fe_pos/model/customer_group_discount.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';

import 'package:provider/provider.dart';

class CustomerGroupDiscountFormPage extends StatefulWidget {
  final CustomerGroupDiscount customerGroupDiscount;
  const CustomerGroupDiscountFormPage(
      {super.key, required this.customerGroupDiscount});

  @override
  State<CustomerGroupDiscountFormPage> createState() =>
      _CustomerGroupDiscountFormPageState();
}

class _CustomerGroupDiscountFormPageState
    extends State<CustomerGroupDiscountFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;
  final _formKey = GlobalKey<FormState>();
  CustomerGroupDiscount get customerGroupDiscount =>
      widget.customerGroupDiscount;
  late final Server _server;
  late final Setting setting;
  final _focusNode = FocusNode();
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    setting = context.read<Setting>();
    _server = context.read<Server>();
    super.initState();
    _focusNode.requestFocus();
  }

  Future? request;
  void _submit() async {
    if (request != null) {
      return;
    }
    Map body = {
      'data': {
        'type': 'customer_group_discount',
        'attributes': customerGroupDiscount.toJson(),
      }
    };

    if (customerGroupDiscount.id == null) {
      request = _server.post('customer_group_discounts', body: body);
    } else {
      request = _server.put(
          'customer_group_discounts/${customerGroupDiscount.id}',
          body: body);
    }
    request?.then((response) {
      request = null;
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          customerGroupDiscount.setFromJson(data,
              included: response.data['included'] ?? []);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget,
              'Edit Customer Group Discount ${customerGroupDiscount.id}');
        });

        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: (data['errors'] ?? []).join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      request = null;
      defaultErrorResponse(error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
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
                    visible: customerGroupDiscount.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () => fetchHistoryByRecord(
                            'CustomerGroupDiscount', customerGroupDiscount.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  Visibility(
                    visible: setting.canShow(
                        'customerGroupDiscount', 'customer_group_code'),
                    child: AsyncDropdown<CustomerGroup>(
                      allowClear: false,
                      modelClass: CustomerGroupClass(),
                      label: const Text(
                        'Customer Group',
                        style: labelStyle,
                      ),
                      path: 'customer_groups',
                      onSaved: (value) => customerGroupDiscount.customerGroup =
                          value ?? customerGroupDiscount.customerGroup,
                      selected: customerGroupDiscount.customerGroup,
                      textOnSearch: (customerGroup) =>
                          "${customerGroup.code} - ${customerGroup.name}",
                      textOnSelected: (customerGroup) => customerGroup.code,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'period_type'),
                    child: DropdownMenu<CustomerGroupDiscountPeriodType>(
                      dropdownMenuEntries: CustomerGroupDiscountPeriodType
                          .values
                          .map<
                              DropdownMenuEntry<
                                  CustomerGroupDiscountPeriodType>>((value) =>
                              DropdownMenuEntry<
                                      CustomerGroupDiscountPeriodType>(
                                  value: value, label: value.humanize()))
                          .toList(),
                      label: const Text(
                        'Tipe Periode',
                        style: labelStyle,
                      ),
                      initialSelection: customerGroupDiscount.periodType,
                      onSelected: (newValue) {
                        customerGroupDiscount.periodType =
                            newValue ?? customerGroupDiscount.periodType;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow(
                        'customerGroupDiscount', 'start_active_date'),
                    child: DateFormField(
                        label: const Text(
                          'Tanggal Mulai Aktif',
                          style: labelStyle,
                        ),
                        datePickerOnly: true,
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          customerGroupDiscount.startActiveDate =
                              Date.parsingDateTime(newValue);
                        },
                        validator: (newValue) {
                          if (newValue == null) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                        onChanged: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          customerGroupDiscount.startActiveDate =
                              Date.parsingDateTime(newValue);
                        },
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 31)),
                        initialValue: customerGroupDiscount.startActiveDate),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow(
                        'customerGroupDiscount', 'end_active_date'),
                    child: DateFormField(
                        label: const Text(
                          'Tanggal terakhir Aktif',
                          style: labelStyle,
                        ),
                        datePickerOnly: true,
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          customerGroupDiscount.endActiveDate =
                              Date.parsingDateTime(newValue);
                        },
                        validator: (newValue) {
                          if (newValue != null &&
                              newValue.isBefore(
                                  customerGroupDiscount.startActiveDate)) {
                            return 'harus lebih besar dari Tanggal mulai kerja';
                          }
                          return null;
                        },
                        allowClear: true,
                        onChanged: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          customerGroupDiscount.endActiveDate =
                              Date.parsingDateTime(newValue);
                        },
                        initialValue: customerGroupDiscount.endActiveDate),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow(
                        'customerGroupDiscount', 'discount_percentage'),
                    child: PercentageFormField(
                      focusNode: _focusNode,
                      label: const Text('Persentase', style: labelStyle),
                      initialValue: customerGroupDiscount.discountPercentage,
                      onChanged: (newValue) {
                        customerGroupDiscount.discountPercentage =
                            newValue ?? const Percentage(0);
                      },
                      validator: (newValue) {
                        if (newValue == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('customerGroupDiscount', 'level'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Level',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.level.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.level =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.level;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.level = int.tryParse(newValue) ??
                            customerGroupDiscount.level;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable1'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 1',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable1 == null
                          ? ''
                          : customerGroupDiscount.variable1.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable1 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable1;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable1 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable1;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable2'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 2',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable2 == null
                          ? ''
                          : customerGroupDiscount.variable2.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable2 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable2;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable2 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable2;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable3'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 3',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable3 == null
                          ? ''
                          : customerGroupDiscount.variable3.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable3 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable3;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable3 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable3;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable4'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 4',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable4 == null
                          ? ''
                          : customerGroupDiscount.variable4.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable4 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable4;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable4 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable4;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable5'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 5',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable5 == null
                          ? ''
                          : customerGroupDiscount.variable5.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable5 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable5;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable5 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable5;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable6'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 6',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable6 == null
                          ? ''
                          : customerGroupDiscount.variable6.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable6 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable6;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable6 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable6;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible:
                        setting.canShow('customerGroupDiscount', 'variable7'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Variable 7',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: customerGroupDiscount.variable7 == null
                          ? ''
                          : customerGroupDiscount.variable7.toString(),
                      onSaved: (newValue) {
                        customerGroupDiscount.variable7 =
                            int.tryParse(newValue ?? '') ??
                                customerGroupDiscount.variable7;
                      },
                      onChanged: (newValue) {
                        customerGroupDiscount.variable7 =
                            int.tryParse(newValue) ??
                                customerGroupDiscount.variable7;
                      },
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
                            flash.show(
                                const Text('Loading'), ToastificationType.info);
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
