import 'package:fe_pos/model/work_schedule.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_picker.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EmployeeFormPage extends StatefulWidget {
  final Employee employee;
  const EmployeeFormPage({super.key, required this.employee});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, HistoryPopup {
  late Flash flash;
  final codeInputWidget = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  Employee get employee => widget.employee;
  late final Server _server;
  Uint8List? _imageBytes;
  late final Setting setting;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    setting = context.read<Setting>();
    _server = context.read<Server>();
    if (employee.imageCode != null) {
      loadImage(employee.imageCode ?? '');
    }
    if (employee.id != null) {
      Future.delayed(Duration.zero, () => fetchEmployee());
    } else {
      employee.schedules = [];
    }
    super.initState();
  }

  void fetchEmployee() {
    showLoadingPopup();
    final server = context.read<Server>();
    server.get('employees/${employee.id}',
        queryParam: {'include': 'work_schedules'}).then((response) {
      if (response.statusCode == 200) {
        final workSchedules = response.data['data']['relationships']
            ['work_schedules']['data'] as List;
        final relationshipsData = response.data['included'] as List;
        setState(() {
          employee.schedules = workSchedules.map<WorkSchedule>((line) {
            final json = relationshipsData.firstWhere((row) =>
                row['type'] == line['type'] && row['id'] == line['id']);
            return WorkSchedule.fromJson(json);
          }).toList();
        });
      }
    }, onError: (error) {
      server.defaultErrorResponse(context: context, error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  Future? request;
  void _submit() async {
    if (request != null) {
      return;
    }
    Map body = {
      'data': {
        'type': 'employee',
        'attributes': employee.toJson(),
        'relationships': {
          'work_schedules': {
            'data': employee.schedules
                .map<Map>((workSchedule) => {
                      'id': workSchedule.id,
                      'type': 'work_schedule',
                      'attributes': workSchedule.toJson()
                    })
                .toList()
          },
        }
      }
    };

    if (employee.id == null) {
      request = _server.post('employees', body: body);
    } else {
      request = _server.put('employees/${employee.id}', body: body);
    }
    request?.then((response) {
      request = null;
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          employee.id = int.tryParse(data['id']);
          employee.code = data['attributes']['code'];
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit Karyawan ${employee.code}');
        });

        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      request = null;
      _server.defaultErrorResponse(context: context, error: error);
    });
  }

  void pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }
    if (await pickedFile.length() > 1024000000) {
      flash.showBanner(
          messageType: MessageType.failed,
          title: 'Gagal Upload gambar',
          description: 'Gambar tidak boleh lebih dari 1MB');
      return;
    }

    _server.upload('assets', pickedFile).then((response) {
      if (response.statusCode == 201) {
        setState(() {
          employee.imageCode = response.data['data']['attributes']['code'];
          if (employee.imageCode != null) {
            loadImage(employee.imageCode ?? '');
          } else {
            _imageBytes = null;
          }
        });
      }
    },
        onError: (error) =>
            _server.defaultErrorResponse(context: context, error: error));
  }

  void loadImage(String imageCode) async {
    final response =
        await _server.get('assets/$imageCode', responseType: 'file');
    if (response.statusCode == 200) {
      setState(() {
        _imageBytes = response.data;
      });
    } else {
      flash.showBanner(
          messageType: MessageType.failed,
          title: 'Gagal',
          description: 'gagal tampilkan gambar');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    codeInputWidget.text = employee.code;
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
                    visible: employee.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () =>
                            fetchHistoryByRecord('Employee', employee.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  Visibility(
                    visible: setting.canShow('employee', 'code'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Kode Karyawan',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      onSaved: (newValue) {
                        employee.code = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.code = newValue.toString();
                      },
                      controller: codeInputWidget,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'name'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Nama Karyawan',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.name,
                      onSaved: (newValue) {
                        employee.name = newValue.toString();
                      },
                      validator: (newValue) {
                        if (newValue == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                      onChanged: (newValue) {
                        employee.name = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'role_id'),
                    child: Flexible(
                      child: AsyncDropdown(
                        path: '/roles',
                        attributeKey: 'name',
                        label: const Text(
                          'Jabatan :',
                          style: labelStyle,
                        ),
                        onChanged: (option) {
                          employee.role.id = int.tryParse(option?.value ?? '');

                          employee.role.name = option?.text ?? '';
                        },
                        selected: employee.role.id == null
                            ? null
                            : DropdownResult(
                                value: employee.role.id,
                                text: employee.role.name),
                        validator: (value) {
                          if (employee.role.id == null) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'status'),
                    child: const Text(
                      'Status:',
                      style: labelStyle,
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'status'),
                    child: RadioListTile<EmployeeStatus>(
                      title: const Text('Inactive'),
                      value: EmployeeStatus.inactive,
                      groupValue: employee.status,
                      onChanged: (value) {
                        setState(() {
                          employee.status = value ?? EmployeeStatus.inactive;
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'status'),
                    child: RadioListTile<EmployeeStatus>(
                      title: const Text('Active'),
                      value: EmployeeStatus.active,
                      groupValue: employee.status,
                      onChanged: (value) {
                        setState(() {
                          employee.status = value ?? EmployeeStatus.inactive;
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.isAuthorize('payroll', 'index') &&
                        setting.canShow('employee', 'payroll_id'),
                    child: AsyncDropdown(
                      label: const Text(
                        'Payroll',
                        style: labelStyle,
                      ),
                      request: (server, offset, searchText) {
                        return server.get('payrolls', queryParam: {
                          'search_text': searchText,
                          'field[payroll]': 'name',
                          'page[offset]': offset.toString(),
                        });
                      },
                      attributeKey: 'name',
                      onChanged: (value) {
                        if (value == null) {
                          employee.payroll = null;
                          return;
                        }
                        employee.payroll = Payroll(
                          id: int.tryParse(value.value ?? ''),
                          name: value.text,
                        );
                      },
                      selected: employee.payroll == null
                          ? null
                          : DropdownResult(
                              value: employee.payroll?.id,
                              text: employee.payroll?.name ?? ''),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'start_working_date'),
                    child: DatePicker(
                        label: const Text(
                          'Tanggal Mulai Kerja',
                          style: labelStyle,
                        ),
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          employee.startWorkingDate =
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
                          employee.startWorkingDate =
                              Date.parsingDateTime(newValue);
                        },
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 31)),
                        initialValue: employee.startWorkingDate),
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'end_working_date'),
                    child: DatePicker(
                        label: const Text(
                          'Tanggal terakhir Kerja',
                          style: labelStyle,
                        ),
                        onSaved: (newValue) {
                          employee.endWorkingDate = newValue == null
                              ? null
                              : Date.parsingDateTime(newValue);
                        },
                        validator: (newValue) {
                          if (newValue != null &&
                              newValue.isBefore(employee.startWorkingDate)) {
                            return 'harus lebih besar dari Tanggal mulai kerja';
                          }
                          return null;
                        },
                        canRemove: true,
                        onChanged: (newValue) {
                          employee.endWorkingDate = newValue == null
                              ? null
                              : Date.parsingDateTime(newValue);
                        },
                        initialValue: employee.endWorkingDate),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'id_number'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'No KTP',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.idNumber,
                      onSaved: (newValue) {
                        employee.idNumber = newValue.toString();
                      },
                      validator: (newValue) {
                        if (newValue == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                      onChanged: (newValue) {
                        employee.idNumber = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'bank'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Bank',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.bank,
                      onSaved: (newValue) {
                        employee.bank = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.bank = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'bank_account'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Rekening Bank',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.bankAccount,
                      onSaved: (newValue) {
                        employee.bankAccount = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.bankAccount = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'bank_register_name'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Bank Atas Nama',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.bankRegisterName,
                      onSaved: (newValue) {
                        employee.bankRegisterName = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.bankRegisterName = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'contact_number'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Kontak',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.contactNumber,
                      keyboardType: TextInputType.phone,
                      onSaved: (newValue) {
                        employee.contactNumber = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.contactNumber = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'address'),
                    child: TextFormField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Alamat',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.address,
                      onSaved: (newValue) {
                        employee.address = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.address = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'description'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.description,
                      maxLines: 4,
                      onSaved: (newValue) {
                        employee.description = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.description = newValue.toString();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    label: const Text('Pilih gambar.'),
                    icon: const Icon(Icons.image),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (_imageBytes != null)
                    Image.memory(
                      _imageBytes!,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('error load image');
                      },
                      width: 150,
                      height: 200,
                    ),
                  const Text(
                    "Jadwal Kerja",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          const DataColumn(
                              label: Text(
                            'Minggu Aktif',
                            style: labelStyle,
                          )),
                          DataColumn(
                              label: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                employee.schedules.clear();
                              });
                            },
                            child: const Text(
                              'hapus semua',
                              style: labelStyle,
                            ),
                          )),
                        ],
                        rows: employee.schedules
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
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
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
                                  DataCell(DropdownMenu<ActiveWeekWorkSchedule>(
                                      initialSelection: workSchedule.activeWeek,
                                      onSelected: ((value) =>
                                          workSchedule.activeWeek = value ??
                                              ActiveWeekWorkSchedule.allWeek),
                                      dropdownMenuEntries: ActiveWeekWorkSchedule
                                          .values
                                          .map<
                                                  DropdownMenuEntry<
                                                      ActiveWeekWorkSchedule>>(
                                              (activeWeek) => DropdownMenuEntry(
                                                  value: activeWeek,
                                                  label: activeWeek.humanize()))
                                          .toList())),
                                  DataCell(Row(
                                    children: [
                                      Visibility(
                                        visible: workSchedule.id != null,
                                        child: IconButton(
                                          onPressed: () {
                                            fetchHistoryByRecord('WorkSchedule',
                                                workSchedule.id);
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
                                            employee.schedules
                                                .remove(workSchedule);
                                          });
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  )),
                                ]))
                            .toList()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () => setState(() {
                              employee.schedules.add(
                                  WorkSchedule(beginWork: '', endWork: ''));
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
