import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/model/work_schedule.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payroll.dart';

import 'package:provider/provider.dart';

class PayrollFormPage extends StatefulWidget {
  final Payroll payroll;
  const PayrollFormPage({super.key, required this.payroll});

  @override
  State<PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends State<PayrollFormPage>
    with AutomaticKeepAliveClientMixin {
  late Flash flash;
  final codeInputWidget = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  Payroll get payroll => widget.payroll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
    if (payroll.id != null) {
      fetchPayroll();
    }
  }

  void fetchPayroll() {
    var sessionState = context.read<SessionState>();
    var server = sessionState.server;
    server.get('payrolls/${payroll.id}', queryParam: {
      'include': 'payroll_lines,work_schedules'
    }).then((response) {
      if (response.statusCode == 200) {
        final payrollLines = response.data['data']['relationships']
            ['payroll_lines']['data'] as List;
        final workSchedules = response.data['data']['relationships']
            ['work_schedules']['data'] as List;
        final relationshipsData = response.data['included'] as List;
        setState(() {
          payroll.lines = payrollLines.map<PayrollLine>((line) {
            final json = relationshipsData.firstWhere((row) =>
                row['type'] == line['type'] && row['id'] == line['id']);
            return PayrollLine.fromJson(json);
          }).toList();
          payroll.schedules = workSchedules.map<WorkSchedule>((line) {
            final json = relationshipsData.firstWhere((row) =>
                row['type'] == line['type'] && row['id'] == line['id']);
            return WorkSchedule.fromJson(json);
          }).toList();
        });
      }
    }, onError: (error) {
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  void _submit() async {
    var sessionState = context.read<SessionState>();
    var server = sessionState.server;
    for (final (int index, PayrollLine payrollLine) in payroll.lines.indexed) {
      payrollLine.row = index + 1;
    }
    Map body = {
      'data': {
        'type': 'payroll',
        'attributes': payroll.toJson(),
        'relationships': {
          'payroll_lines': {
            'data': payroll.lines
                .map<Map>((payrollLine) => {
                      'id': payrollLine.id,
                      'type': 'payroll_line',
                      'attributes': payrollLine.toJson()
                    })
                .toList()
          },
          'work_schedules': {
            'data': payroll.schedules
                .map<Map>((workSchedule) => {
                      'id': workSchedule.id,
                      'type': 'work_schedule',
                      'attributes': workSchedule.toJson()
                    })
                .toList()
          }
        }
      }
    };
    Future request;
    if (payroll.id == null) {
      request = server.post('payrolls', body: body);
    } else {
      request = server.put('payrolls/${payroll.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          payroll.id = int.tryParse(data['id']);
          payroll.name = data['attributes']['name'];
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit payroll ${payroll.name}');
        });
        fetchPayroll();
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
    codeInputWidget.text = payroll.name;
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
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
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Nama',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      payroll.name = newValue.toString();
                    },
                    onChanged: (newValue) {
                      payroll.name = newValue.toString();
                    },
                    controller: codeInputWidget,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Paid Time Off',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payroll.paidTimeOff.toString(),
                    onSaved: (newValue) {
                      payroll.paidTimeOff = int.parse(newValue.toString());
                    },
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      payroll.paidTimeOff = int.parse(newValue.toString());
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: payroll.description,
                    maxLines: 4,
                    onSaved: (newValue) {
                      payroll.description = newValue.toString();
                    },
                    onChanged: (newValue) {
                      payroll.description = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "Jadwal Kerja",
                    style: labelStyle,
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
                            'Hari',
                            style: labelStyle,
                          )),
                          const DataColumn(
                              label: Text(
                            'Shift',
                            style: labelStyle,
                          )),
                          const DataColumn(
                              label: Text(
                            'Mulai',
                            style: labelStyle,
                          )),
                          const DataColumn(
                              label: Text(
                            'Akhir',
                            style: labelStyle,
                          )),
                          DataColumn(
                              label: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                payroll.schedules.clear();
                              });
                            },
                            child: const Text(
                              'hapus semua',
                              style: labelStyle,
                            ),
                          )),
                        ],
                        rows: payroll.schedules
                            .map<DataRow>((workSchedule) => DataRow(cells: [
                                  DataCell(DropdownMenu<int>(
                                    initialSelection: workSchedule.dayOfWeek,
                                    onSelected: ((value) =>
                                        workSchedule.dayOfWeek = value ?? 0),
                                    dropdownMenuEntries: const [
                                      DropdownMenuEntry(
                                          value: 1, label: 'Senin'),
                                      DropdownMenuEntry(
                                          value: 2, label: 'Selasa'),
                                      DropdownMenuEntry(
                                          value: 3, label: 'Rabu'),
                                      DropdownMenuEntry(
                                          value: 4, label: 'Kamis'),
                                      DropdownMenuEntry(
                                          value: 5, label: 'Jumat'),
                                      DropdownMenuEntry(
                                          value: 6, label: 'Sabtu'),
                                      DropdownMenuEntry(
                                          value: 7, label: 'Minggu'),
                                    ],
                                  )),
                                  DataCell(TextFormField(
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder()),
                                    initialValue: workSchedule.shift.toString(),
                                    keyboardType: TextInputType.number,
                                    onSaved: (value) => workSchedule.shift =
                                        int.parse(value ?? '1'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'harus diisi';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'tidak valid';
                                      }
                                      if (int.parse(value) <= 0) {
                                        return 'harus lebih besar dari 0';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => workSchedule.shift =
                                        int.tryParse(value) ?? 0,
                                  )),
                                  DataCell(TextFormField(
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder()),
                                    initialValue: workSchedule.beginWork,
                                    onSaved: (value) =>
                                        workSchedule.beginWork = value ?? '',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        workSchedule.beginWork = value,
                                  )),
                                  DataCell(TextFormField(
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder()),
                                    initialValue: workSchedule.endWork,
                                    onSaved: (value) =>
                                        workSchedule.endWork = value ?? '',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        workSchedule.endWork = value,
                                  )),
                                  DataCell(ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        payroll.schedules.remove(workSchedule);
                                      });
                                    },
                                    child: const Text('hapus'),
                                  ))
                                ]))
                            .toList()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              payroll.schedules.add(
                                  WorkSchedule(beginWork: '', endWork: ''));
                            }),
                        child: const Text('Tambah')),
                  ),
                  const Text(
                    "Lines",
                    style: labelStyle,
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
                            label: Text('Tipe Payroll', style: labelStyle)),
                        const DataColumn(
                            label: Text('formula', style: labelStyle)),
                        const DataColumn(
                            label: Text('description', style: labelStyle)),
                        const DataColumn(
                            label: Text('variable1', style: labelStyle)),
                        const DataColumn(
                            label: Text('variable2', style: labelStyle)),
                        const DataColumn(
                            label: Text('variable3', style: labelStyle)),
                        const DataColumn(
                            label: Text('variable4', style: labelStyle)),
                        const DataColumn(
                            label: Text('variable5', style: labelStyle)),
                        DataColumn(
                            label: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    payroll.lines.clear();
                                  });
                                },
                                child: const Text('Hapus Semua',
                                    style: labelStyle))),
                      ],
                      rows: payroll.lines
                          .map<DataRow>((payrollLine) => DataRow(cells: [
                                DataCell(DropdownMenu<PayrollGroup>(
                                  initialSelection: payrollLine.group,
                                  onSelected: (value) => payrollLine.group =
                                      value ?? PayrollGroup.earning,
                                  dropdownMenuEntries: PayrollGroup.values
                                      .map<DropdownMenuEntry<PayrollGroup>>(
                                          (value) => DropdownMenuEntry(
                                              value: value,
                                              label: value.toString()))
                                      .toList(),
                                )),
                                DataCell(DropdownMenu<PayrollType>(
                                  initialSelection: payrollLine.payrollType,
                                  onSelected: (value) =>
                                      payrollLine.payrollType = value,
                                  dropdownMenuEntries: PayrollType.values
                                      .map<DropdownMenuEntry<PayrollType>>(
                                          (value) => DropdownMenuEntry(
                                              value: value,
                                              label: value.toString()))
                                      .toList(),
                                )),
                                DataCell(DropdownMenu<PayrollFormula>(
                                  initialSelection: payrollLine.formula,
                                  onSelected: (value) => payrollLine.formula =
                                      value ?? PayrollFormula.basic,
                                  dropdownMenuEntries: PayrollFormula.values
                                      .map<DropdownMenuEntry<PayrollFormula>>(
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
                                    initialValue: payrollLine.description,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        payrollLine.description = value,
                                    onSaved: (value) =>
                                        payrollLine.description = value ?? '',
                                    key: ValueKey(
                                        "${payrollLine.id ?? payrollLine.row}-decription"),
                                  ),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      (payrollLine.variable1 ?? '').toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => payrollLine.variable1 =
                                      double.tryParse(value),
                                  onSaved: (value) => payrollLine.variable1 =
                                      double.tryParse(value ?? ''),
                                  key: ValueKey(
                                      "${payrollLine.id ?? payrollLine.row}-variable1"),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      (payrollLine.variable2 ?? '').toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => payrollLine.variable2 =
                                      double.tryParse(value),
                                  onSaved: (value) => payrollLine.variable2 =
                                      double.tryParse(value ?? ''),
                                  key: ValueKey(
                                      "${payrollLine.id ?? payrollLine.row}-variable2"),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      (payrollLine.variable3 ?? '').toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => payrollLine.variable3 =
                                      double.tryParse(value),
                                  onSaved: (value) => payrollLine.variable3 =
                                      double.tryParse(value ?? ''),
                                  key: ValueKey(
                                      "${payrollLine.id ?? payrollLine.row}-variable3"),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      (payrollLine.variable4 ?? '').toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => payrollLine.variable4 =
                                      double.tryParse(value),
                                  onSaved: (value) => payrollLine.variable4 =
                                      double.tryParse(value ?? ''),
                                  key: ValueKey(
                                      "${payrollLine.id ?? payrollLine.row}-variable4"),
                                )),
                                DataCell(TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      (payrollLine.variable5 ?? '').toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => payrollLine.variable5 =
                                      double.tryParse(value),
                                  onSaved: (value) => payrollLine.variable5 =
                                      double.tryParse(value ?? ''),
                                  key: ValueKey(
                                      "${payrollLine.id ?? payrollLine.row}-variable5"),
                                )),
                                DataCell(ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      payroll.lines.remove(payrollLine);
                                    });
                                  },
                                  child: const Text('Hapus'),
                                ))
                              ]))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              payroll.lines.add(PayrollLine(
                                  group: PayrollGroup.earning,
                                  formula: PayrollFormula.basic,
                                  row: payroll.lines.length));
                            }),
                        child: const Text('Tambah')),
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
