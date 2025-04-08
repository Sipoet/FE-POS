import 'package:fe_pos/model/book_payslip_line.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';

import 'package:provider/provider.dart';

class BookPayslipLineFormPage extends StatefulWidget {
  final BookPayslipLine bookPayslipLine;
  const BookPayslipLineFormPage({super.key, required this.bookPayslipLine});

  @override
  State<BookPayslipLineFormPage> createState() =>
      _BookPayslipLineFormPageState();
}

class _BookPayslipLineFormPageState extends State<BookPayslipLineFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;
  final _formKey = GlobalKey<FormState>();
  BookPayslipLine get bookPayslipLine => widget.bookPayslipLine;
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
        'type': 'book_payslip_line',
        'attributes': bookPayslipLine.toJson(),
      }
    };

    if (bookPayslipLine.id == null) {
      request = _server.post('book_payslip_lines', body: body);
    } else {
      request =
          _server.put('book_payslip_lines/${bookPayslipLine.id}', body: body);
    }
    request?.then((response) {
      request = null;
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          BookPayslipLine.fromJson(data,
              model: bookPayslipLine,
              included: response.data['included'] ?? []);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit BookPayslipLine ${bookPayslipLine.id}');
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
                    visible: bookPayslipLine.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () => fetchHistoryByRecord(
                            'BookPayslipLine', bookPayslipLine.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  DateFormField(
                      label: const Text(
                        'Tanggal',
                        style: labelStyle,
                      ),
                      datePickerOnly: true,
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        bookPayslipLine.transactionDate =
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
                        bookPayslipLine.transactionDate =
                            Date.parsingDateTime(newValue);
                      },
                      initialValue: bookPayslipLine.transactionDate),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownMenu<PayrollGroup>(
                    initialSelection: bookPayslipLine.group,
                    onSelected: (value) =>
                        bookPayslipLine.group = value ?? PayrollGroup.earning,
                    dropdownMenuEntries: PayrollGroup.values
                        .map<DropdownMenuEntry<PayrollGroup>>((value) =>
                            DropdownMenuEntry(
                                value: value, label: value.toString()))
                        .toList(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AsyncDropdown<Employee>(
                    label:
                        Text(setting.columnName('bookPayslipLine', 'employee')),
                    converter: Employee.fromJson,
                    allowClear: false,
                    path: 'employees',
                    selected: bookPayslipLine.employee,
                    textOnSearch: (employee) => employee.name,
                    onChanged: (employee) =>
                        bookPayslipLine.employee = employee ?? Employee(),
                    onSaved: (employee) =>
                        bookPayslipLine.employee = employee ?? Employee(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AsyncDropdown<PayrollType>(
                    label: Text(
                        setting.columnName('bookPayslipLine', 'payroll_type')),
                    converter: PayrollType.fromJson,
                    allowClear: false,
                    path: 'payroll_types',
                    selected: bookPayslipLine.payrollType,
                    textOnSearch: (payrollType) => payrollType.name,
                    onChanged: (payrollType) => bookPayslipLine.payrollType =
                        payrollType ?? PayrollType(),
                    onSaved: (payrollType) => bookPayslipLine.payrollType =
                        payrollType ?? PayrollType(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        label: Text(
                          'Deskripsi',
                          style: labelStyle,
                        ),
                        border: OutlineInputBorder()),
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (value) => bookPayslipLine.description = value,
                    initialValue: bookPayslipLine.description,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  MoneyFormField(
                    initialValue: bookPayslipLine.amount,
                    label:
                        Text(setting.columnName('bookPayslipLine', 'amount')),
                    onChanged: (value) =>
                        bookPayslipLine.amount = value ?? Money(0),
                    validator: (value) {
                      if (value == null) {
                        return 'tidak valid';
                      }
                      if (value <= 0) {
                        return 'harus lebih besar dari 0';
                      }
                      return null;
                    },
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
