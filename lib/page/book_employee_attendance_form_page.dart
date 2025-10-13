import 'package:fe_pos/model/book_employee_attendance.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookEmployeeAttendanceFormPage extends StatefulWidget {
  final BookEmployeeAttendance bookEmployeeAttendance;
  const BookEmployeeAttendanceFormPage(
      {super.key, required this.bookEmployeeAttendance});

  @override
  State<BookEmployeeAttendanceFormPage> createState() =>
      _BookEmployeeAttendanceFormPageState();
}

class _BookEmployeeAttendanceFormPageState
    extends State<BookEmployeeAttendanceFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;
  final _formKey = GlobalKey<FormState>();
  BookEmployeeAttendance get bookEmployeeAttendance =>
      widget.bookEmployeeAttendance;
  late final Server _server;
  late final Setting setting;
  List<Employee> _employees = [];
  final List<BookEmployeeAttendance> _bookEmployeeAttendances = [];
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

  void _submit() async {
    if (_employees.isNotEmpty && bookEmployeeAttendance.isNewRecord) {
      multipleCreate();
    } else {
      createOrUpdateRecord(bookEmployeeAttendance);
    }
  }

  Future<BookEmployeeAttendance?> createOrUpdateRecord(
      BookEmployeeAttendance record) {
    Map body = {
      'data': {
        'type': 'book_employee_attendance',
        'attributes': record.toJson(),
      }
    };
    Future<dynamic> request;
    if (record.id == null) {
      request = _server.post('book_employee_attendances', body: body);
    } else {
      request =
          _server.put('book_employee_attendances/${record.id}', body: body);
    }
    return request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          record.setFromJson(data, included: response.data['included'] ?? []);
          final tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit BookEmployeeAttendance ${record.id}');
        });

        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
        return record;
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: (data['errors'] ?? []).join('\n'),
            messageType: ToastificationType.error);
      }
      return null;
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
      return null;
    });
  }

  void multipleCreate() {
    for (Employee employee in _employees) {
      var record = BookEmployeeAttendance(
        employee: employee,
        isFlexible: bookEmployeeAttendance.isFlexible,
        isLate: bookEmployeeAttendance.isLate,
        allowOvertime: bookEmployeeAttendance.allowOvertime,
        description: bookEmployeeAttendance.description,
        startDate: bookEmployeeAttendance.startDate,
        endDate: bookEmployeeAttendance.endDate,
      );
      createOrUpdateRecord(record).then(
        (value) {
          if (value != null) {
            setState(() {
              _bookEmployeeAttendances.add(value);
            });
          }
        },
      );
    }
  }

  void _editRecord(BookEmployeeAttendance line) {
    final tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit BookEmployeeAttendance ${line.id}',
          BookEmployeeAttendanceFormPage(
              key: ObjectKey(line), bookEmployeeAttendance: line));
    });
  }

  void _destroyRecord(BookEmployeeAttendance line) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${line.id}?',
        onSubmit: () {
          _server.delete('/book_employee_attendances/${line.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus BookEmployeeAttendance ${line.id}');

              setState(() {
                _bookEmployeeAttendances.remove(line);
              });
            }
          }, onError: (error) {
            defaultErrorResponse(error: error);
          });
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
                    visible: bookEmployeeAttendance.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () => fetchHistoryByRecord(
                            'BookEmployeeAttendance',
                            bookEmployeeAttendance.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  DateRangeFormField(
                      label: const Text(
                        'Tanggal',
                        style: labelStyle,
                      ),
                      datePickerOnly: true,
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        bookEmployeeAttendance.startDate =
                            Date.parsingDateTime(newValue.start);
                        bookEmployeeAttendance.endDate =
                            Date.parsingDateTime(newValue.end);
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
                        bookEmployeeAttendance.startDate =
                            Date.parsingDateTime(newValue.start);
                        bookEmployeeAttendance.endDate =
                            Date.parsingDateTime(newValue.end);
                      },
                      initialDateRange: DateTimeRange(
                          start: bookEmployeeAttendance.startDate,
                          end: bookEmployeeAttendance.endDate)),
                  const SizedBox(
                    height: 10,
                  ),
                  Offstage(
                    offstage: bookEmployeeAttendance.isNewRecord,
                    child: AsyncDropdown<Employee>(
                      label: Text(setting.columnName(
                          'bookEmployeeAttendance', 'employee')),
                      modelClass: EmployeeClass(),
                      allowClear: false,
                      path: 'employees',
                      selected: bookEmployeeAttendance.employee,
                      textOnSearch: (employee) => employee.name,
                      onChanged: (employee) => bookEmployeeAttendance.employee =
                          employee ?? Employee(),
                      onSaved: (employee) => bookEmployeeAttendance.employee =
                          employee ?? Employee(),
                    ),
                  ),
                  Offstage(
                    offstage: !bookEmployeeAttendance.isNewRecord,
                    child: AsyncDropdownMultiple<Employee>(
                      label: Text(setting.columnName(
                          'bookEmployeeAttendance', 'employee')),
                      modelClass: EmployeeClass(),
                      path: 'employees',
                      textOnSearch: (employee) => employee.name,
                      onChanged: (employees) => _employees = employees,
                      onSaved: (employees) =>
                          _employees = employees ?? _employees,
                    ),
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
                    onChanged: (value) =>
                        bookEmployeeAttendance.description = value,
                    initialValue: bookEmployeeAttendance.description,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: 300,
                    child: CheckboxListTile(
                        value: bookEmployeeAttendance.isFlexible,
                        tristate: true,
                        title: Text('Jam Flexible?'),
                        onChanged: (value) => setState(() {
                              bookEmployeeAttendance.isFlexible = value;
                            })),
                  ),
                  SizedBox(
                    width: 300,
                    child: CheckboxListTile(
                        value: bookEmployeeAttendance.isLate,
                        tristate: true,
                        title: Text('Telat?'),
                        onChanged: (value) => setState(() {
                              bookEmployeeAttendance.isLate = value;
                            })),
                  ),
                  SizedBox(
                    width: 300,
                    child: CheckboxListTile(
                        value: bookEmployeeAttendance.allowOvertime,
                        tristate: true,
                        title: Text('boleh overtime?'),
                        onChanged: (value) => setState(() {
                              bookEmployeeAttendance.allowOvertime = value;
                            })),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: _bookEmployeeAttendances.isEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              flash.show(const Text('Loading'),
                                  ToastificationType.info);
                              _submit();
                            }
                          },
                          child: const Text('submit')),
                    ),
                  ),
                  Visibility(
                    visible: _bookEmployeeAttendances.isNotEmpty,
                    child: Table(
                      border: TableBorder.all(),
                      children: [
                            TableRow(
                              children: [
                                TableCell(
                                    child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Nama Karyawan',
                                    style: labelStyle,
                                  ),
                                )),
                                TableCell(
                                    child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Action', style: labelStyle),
                                )),
                              ],
                            ),
                          ] +
                          _bookEmployeeAttendances
                              .map<TableRow>((line) => TableRow(
                                    key: ObjectKey(line.id),
                                    children: [
                                      TableCell(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(line.employee?.name ?? ''),
                                      )),
                                      TableCell(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                                onPressed: () =>
                                                    _editRecord(line),
                                                icon: Icon(Icons.edit)),
                                            IconButton(
                                                onPressed: () =>
                                                    _destroyRecord(line),
                                                icon: Icon(Icons.close)),
                                          ],
                                        ),
                                      ))
                                    ],
                                  ))
                              .toList(),
                    ),
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
