import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payslip.dart';

import 'package:provider/provider.dart';

class PayslipFormPage extends StatefulWidget {
  final Payslip payslip;
  const PayslipFormPage({super.key, required this.payslip});

  @override
  State<PayslipFormPage> createState() => _PayslipFormPageState();
}

class _PayslipFormPageState extends State<PayslipFormPage>
    with
        AutomaticKeepAliveClientMixin,
        HistoryPopup,
        LoadingPopup,
        TextFormatter {
  late Flash flash;
  late final Setting setting;
  final _formKey = GlobalKey<FormState>();
  Payslip get payslip => widget.payslip;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    setting = context.read<Setting>();
    flash = Flash(context);
    super.initState();
    if (payslip.id != null) {
      Future.delayed(Duration.zero, () => fetchPayslip());
    }
  }

  void fetchPayslip() {
    showLoadingPopup();
    final server = context.read<Server>();
    server.get('payslips/${payslip.id}',
        queryParam: {'include': 'payslip_lines'}).then((response) {
      if (response.statusCode == 200) {
        final payslipLines = response.data['data']['relationships']
            ['payslip_lines']['data'] as List;
        final relationshipsData = response.data['included'] as List;
        setState(() {
          payslip.lines = payslipLines.map<PayslipLine>((line) {
            final json = relationshipsData.firstWhere((row) =>
                row['type'] == line['type'] && row['id'] == line['id']);
            return PayslipLine.fromJson(json);
          }).toList();
        });
      }
    }, onError: (error) {
      server.defaultErrorResponse(context: context, error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'payslip',
        'attributes': payslip.toJson(),
        'relationships': {
          'payslip_lines': {
            'data': payslip.lines
                .map<Map>((payslipLine) => {
                      'id': payslipLine.id,
                      'type': 'payslip_line',
                      'attributes': payslipLine.toJson()
                    })
                .toList()
          }
        }
      }
    };
    Future request;
    if (payslip.id == null) {
      request = server.post('payslips', body: body);
    } else {
      request = server.put('payslips/${payslip.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        final data = response.data['data'];
        setState(() {
          payslip.id = int.tryParse(data['id']);
          final attributes = data['attributes'];
          if (attributes != null) {
            payslip.status = PayslipStatus.fromString(attributes['status']);
            payslip.grossSalary =
                double.tryParse(attributes['gross_salary']) ?? 0;
            payslip.taxAmount = double.tryParse(attributes['tax_amount']) ?? 0;
            payslip.nettSalary =
                double.tryParse(attributes['nett_salary']) ?? 0;
          }
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit payslip ${payslip.id}');
        });
        fetchPayslip();
        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        final data = response.data;
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
    // codeInputWidget.text = payslip.name;
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
                    visible: payslip.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () =>
                            fetchHistoryByRecord('Payslip', payslip.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  AsyncDropdown<Employee>(
                    path: 'employees',
                    attributeKey: 'name',
                    onChanged: (value) {
                      payslip.employee = value ?? Employee();
                    },
                    converter: Employee.fromJson,
                    selected: payslip.employee,
                    textOnSearch: (employee) =>
                        "${employee.code} - ${employee.name}",
                    width: 200,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DateFormField(
                      label: const Text('Tanggal Mulai'),
                      onChanged: (value) {
                        if (value != null) {
                          payslip.startDate = Date.parsingDateTime(value);
                        }
                      },
                      initialValue: payslip.startDate),
                  DateFormField(
                      label: const Text('Tanggal Akhir'),
                      onChanged: (value) {
                        if (value != null) {
                          payslip.endDate = Date.parsingDateTime(value);
                        }
                      },
                      initialValue: payslip.endDate),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Paid Time Off',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.paidTimeOff.toString(),
                    onSaved: (newValue) {
                      payslip.paidTimeOff = int.parse(newValue.toString());
                    },
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      payslip.paidTimeOff = int.parse(newValue.toString());
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    enabled: false,
                    decoration: const InputDecoration(
                        labelText: 'Jumlah Hari Kerja',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.workDays.toString(),
                    onSaved: (newValue) {
                      payslip.workDays = double.parse(newValue.toString());
                    },
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      payslip.workDays = double.parse(newValue.toString());
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Lembur dalam Jam',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.overtimeHour.toString(),
                    onSaved: (newValue) {
                      payslip.overtimeHour = double.parse(newValue.toString());
                    },
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      payslip.overtimeHour = double.parse(newValue.toString());
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Sick Leave',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      payslip.sickLeave = int.parse(newValue ?? '0');
                    },
                    onChanged: (newValue) {
                      payslip.sickLeave = int.parse(newValue);
                    },
                    initialValue: payslip.sickLeave.toString(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Izin Cuti',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.knownAbsence.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      payslip.knownAbsence = int.parse(newValue ?? '0');
                    },
                    onChanged: (newValue) {
                      payslip.knownAbsence = int.parse(newValue);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Absen Tanpa Kabar',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.unknownAbsence.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      payslip.unknownAbsence = int.parse(newValue ?? '0');
                    },
                    onChanged: (newValue) {
                      payslip.unknownAbsence = int.parse(newValue);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Telat',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.late.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      payslip.late = int.parse(newValue ?? '0');
                    },
                    onChanged: (newValue) {
                      payslip.late = int.parse(newValue);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Notes',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payslip.notes,
                    maxLines: 4,
                    onSaved: (newValue) {
                      payslip.notes = newValue.toString();
                    },
                    onChanged: (newValue) {
                      payslip.notes = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 100,
                      showBottomBorder: true,
                      columns: [
                        const DataColumn(
                            label: Text(
                          'Grup',
                          style: labelStyle,
                        )),
                        const DataColumn(
                            label: Text('Tipe Payslip', style: labelStyle)),
                        const DataColumn(
                            label: Text('description', style: labelStyle)),
                        const DataColumn(
                            label: Text('amount', style: labelStyle)),
                        DataColumn(
                            label: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    payslip.lines.clear();
                                  });
                                },
                                child: const Text('Hapus Semua',
                                    style: labelStyle))),
                      ],
                      rows: payslip.lines
                          .map<DataRow>((payslipLine) => DataRow(cells: [
                                DataCell(DropdownMenu<PayrollGroup>(
                                  initialSelection: payslipLine.group,
                                  onSelected: (value) => payslipLine.group =
                                      value ?? PayrollGroup.earning,
                                  dropdownMenuEntries: PayrollGroup.values
                                      .map<DropdownMenuEntry<PayrollGroup>>(
                                          (value) => DropdownMenuEntry(
                                              value: value,
                                              label: value.toString()))
                                      .toList(),
                                )),
                                DataCell(DropdownMenu<PayrollType>(
                                  initialSelection: payslipLine.payslipType,
                                  onSelected: (value) =>
                                      payslipLine.payslipType = value,
                                  dropdownMenuEntries: PayrollType.values
                                      .map<DropdownMenuEntry<PayrollType>>(
                                          (value) => DropdownMenuEntry(
                                              value: value,
                                              label: value.toString()))
                                      .toList(),
                                )),
                                DataCell(SizedBox(
                                  width: 250,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder()),
                                    maxLines: 3,
                                    initialValue: payslipLine.description,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        payslipLine.description = value,
                                    onSaved: (value) =>
                                        payslipLine.description = value ?? '',
                                    key: ValueKey(
                                        "${payslipLine.id}-decription"),
                                  ),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue: payslipLine.amount.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      payslipLine.amount = double.parse(value),
                                  onSaved: (value) => payslipLine.amount =
                                      double.parse(value ?? ''),
                                  key: ValueKey("${payslipLine.id}-amount"),
                                )),
                                DataCell(Row(
                                  children: [
                                    Visibility(
                                      visible: payslipLine.id != null,
                                      child: IconButton(
                                        onPressed: () {
                                          fetchHistoryByRecord(
                                              'PayslipLine', payslipLine.id);
                                        },
                                        icon: const Icon(Icons.history),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          payslip.lines.remove(payslipLine);
                                        });
                                      },
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ))
                              ]))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              payslip.lines.add(PayslipLine(
                                group: PayrollGroup.earning,
                                amount: 0,
                              ));
                            }),
                        child: const Text('Tambah')),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 300,
                      child: Table(
                        children: [
                          TableRow(children: [
                            const Text(
                              "Jumlah Kotor :",
                              style: labelStyle,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              moneyFormat(payslip.grossSalary),
                              textAlign: TextAlign.right,
                            ),
                          ]),
                          TableRow(children: [
                            const Text(
                              "PPH :",
                              style: labelStyle,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              moneyFormat(payslip.taxAmount),
                              textAlign: TextAlign.right,
                            ),
                          ]),
                          TableRow(children: [
                            const Text(
                              "Jumlah Bersih :",
                              style: labelStyle,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              moneyFormat(payslip.nettSalary),
                              textAlign: TextAlign.right,
                            ),
                          ])
                        ],
                      ),
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
