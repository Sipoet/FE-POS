import 'package:fe_pos/model/employee_attendance.dart';
import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';
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
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
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
    flash = Flash();
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
    _server.get('employees/${employee.id}', queryParam: {
      'include': 'work_schedules,employee_day_offs,payroll,role'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          employee.setFromJson(
            response.data['data'],
            included: response.data['included'],
          );
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
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
          'employee_day_offs': {
            'data': employee.employeeDayOffs
                .map<Map>((employeeDayOff) => {
                      'id': employeeDayOff.id,
                      'type': 'employee_day_off',
                      'attributes': employeeDayOff.toJson()
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

  void pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }
    if (await pickedFile.length() > 1024000000) {
      flash.showBanner(
          messageType: ToastificationType.error,
          title: 'Gagal Upload gambar',
          description: 'Gambar tidak boleh lebih dari 1MB');
      return;
    }

    _server.upload('assets', file: pickedFile, filename: pickedFile.name).then(
        (response) {
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
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  bool isValidEmail(String value) {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(value);
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
          messageType: ToastificationType.error,
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
                          labelText: 'Nama di Mesin Absensi Karyawan',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      onSaved: (newValue) {
                        employee.code = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.code = newValue.toString();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harus diisi';
                        }
                        return null;
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
                        if (newValue == null || newValue.isEmpty) {
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
                      visible: setting.canShow('employee', 'user_code'),
                      child: AsyncDropdown<HashModel>(
                        label: const Text(
                          'User',
                          style: labelStyle,
                        ),
                        path: 'ipos/users',
                        textOnSearch: (value) => value.id.toString(),
                        attributeKey: 'name',
                        onChanged: (userCode) {
                          employee.userCode = userCode?.id;
                        },
                        modelClass: HashModelClass(),
                        selected: employee.userCode == null
                            ? null
                            : HashModel(id: employee.userCode),
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.isAuthorize('role', 'index') &&
                        setting.canShow('employee', 'role'),
                    child: Flexible(
                      child: AsyncDropdown<Role>(
                        path: '/roles',
                        attributeKey: 'name',
                        label: const Text(
                          'Jabatan :',
                          style: labelStyle,
                        ),
                        onChanged: (role) {
                          employee.role = role ?? Role(name: '');
                        },
                        allowClear: false,
                        textOnSearch: (role) => role.name,
                        modelClass: RoleClass(),
                        selected: employee.role,
                        validator: (role) {
                          if (role == null) {
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
                          setting.canShow('employee', 'payroll'),
                      child: AsyncDropdown<Payroll>(
                        label: const Text(
                          'Payroll',
                          style: labelStyle,
                        ),
                        path: 'payrolls',
                        textOnSearch: (payroll) => payroll.name,
                        attributeKey: 'name',
                        onChanged: (payroll) {
                          employee.payroll = payroll;
                        },
                        modelClass: PayrollClass(),
                        selected: employee.payroll,
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownMenu<Religion>(
                    width: 200,
                    menuHeight: 200,
                    label: Text('Agama'),
                    initialSelection: employee.religion,
                    onSelected: (value) =>
                        employee.religion = value ?? employee.religion,
                    dropdownMenuEntries: Religion.values
                        .map<DropdownMenuEntry<Religion>>((religion) =>
                            DropdownMenuEntry<Religion>(
                                value: religion, label: religion.humanize()))
                        .toList(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Email Karyawan',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return isValidEmail(value) ? null : 'Email tidak valid';
                    },
                    keyboardType: TextInputType.emailAddress,
                    initialValue: employee.email,
                    onSaved: (newValue) {
                      employee.email = newValue.toString();
                    },
                    onChanged: (newValue) {
                      employee.email = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'start_working_date'),
                    child: DateFormField(
                        label: const Text(
                          'Tanggal Mulai Kerja',
                          style: labelStyle,
                        ),
                        helpText: 'Tanggal Mulai Kerja',
                        datePickerOnly: true,
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
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'end_working_date'),
                    child: DateFormField(
                        label: const Text(
                          'Tanggal terakhir Kerja',
                          style: labelStyle,
                        ),
                        helpText: 'Tanggal terakhir Kerja',
                        datePickerOnly: true,
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
                        allowClear: true,
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
                    visible: setting.canShow('employee', 'marital_status'),
                    child: DropdownMenu<EmployeeMaritalStatus>(
                        initialSelection: employee.maritalStatus,
                        onSelected: ((value) => employee.maritalStatus =
                            value ?? EmployeeMaritalStatus.single),
                        dropdownMenuEntries: EmployeeMaritalStatus.values
                            .map<DropdownMenuEntry<EmployeeMaritalStatus>>(
                                (maritalStatus) => DropdownMenuEntry(
                                    value: maritalStatus,
                                    label: maritalStatus.humanize()))
                            .toList()),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('employee', 'tax_number'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'NPWP',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: employee.taxNumber,
                      onSaved: (newValue) {
                        employee.taxNumber = newValue.toString();
                      },
                      onChanged: (newValue) {
                        employee.taxNumber = newValue.toString();
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
                    "Jadwal Libur Mingguan",
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
                        rows: employee.employeeDayOffs
                            .map<DataRow>((employeeDayOff) => DataRow(cells: [
                                  DataCell(DropdownMenu<int>(
                                    initialSelection: employeeDayOff.dayOfWeek,
                                    onSelected: ((value) =>
                                        employeeDayOff.dayOfWeek = value ?? 0),
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
                                  DataCell(DropdownMenu<ActiveWeekDayOff>(
                                      initialSelection:
                                          employeeDayOff.activeWeek,
                                      onSelected: ((value) => employeeDayOff
                                              .activeWeek =
                                          value ?? ActiveWeekDayOff.allWeek),
                                      dropdownMenuEntries: ActiveWeekDayOff
                                          .values
                                          .map<
                                                  DropdownMenuEntry<
                                                      ActiveWeekDayOff>>(
                                              (activeWeek) => DropdownMenuEntry(
                                                  value: activeWeek,
                                                  label: activeWeek.humanize()))
                                          .toList())),
                                  DataCell(Row(
                                    children: [
                                      Visibility(
                                        visible: employeeDayOff.id != null,
                                        child: IconButton(
                                          onPressed: () {
                                            fetchHistoryByRecord(
                                                'EmployeeDayOff',
                                                employeeDayOff.id);
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
                                            employee.employeeDayOffs
                                                .remove(employeeDayOff);
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
                              employee.employeeDayOffs.add(EmployeeDayOff());
                            }),
                        child: const Text('Tambah')),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
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
