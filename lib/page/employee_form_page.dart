import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_picker.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EmployeeFormPage extends StatefulWidget {
  final Employee employee;
  const EmployeeFormPage({super.key, required this.employee});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with AutomaticKeepAliveClientMixin {
  late Flash flash;
  final codeInputWidget = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  Employee get employee => widget.employee;
  late final Server _server;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
    final sessionState = context.read<SessionState>();
    _server = sessionState.server;
  }

  void _submit() async {
    Map body = {'employee': employee};
    Future request;
    if (employee.id == null) {
      request = _server.post('employees', body: body);
    } else {
      request = _server.put('employees/${employee.code}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          employee.id = int.tryParse(data['id']);
          employee.code = data['attributes']['code'];
          employee.imageId = data['attributes']['image_id'];
          employee.imagePath = null;
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

    _server.upload('assets/temporary_file', pickedFile).then((response) {
      if (response.statusCode == 200) {
        employee.imagePath = response.data['data']['id'];
      }
    },
        onError: (error) =>
            _server.defaultErrorResponse(context: context, error: error));
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
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: AsyncDropdownFormField(
                      path: '/roles',
                      attributeKey: 'name',
                      label: const Text(
                        'Jabatan :',
                        style: labelStyle,
                      ),
                      onChanged: (option) {
                        employee.role.id =
                            int.tryParse(option?[0].getValueAsString() ?? '');
                        final text = option?[0].getText() as Text;
                        employee.role.name = text.data ?? '';
                      },
                      selected: [
                        BsSelectBoxOption(
                            value: employee.role.id,
                            text: Text(employee.role.name)),
                      ],
                      validator: (value) {
                        if (employee.role.id == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Text(
                    'Status:',
                    style: labelStyle,
                  ),
                  RadioListTile<EmployeeStatus>(
                    title: const Text('Inactive'),
                    value: EmployeeStatus.inactive,
                    groupValue: employee.status,
                    onChanged: (value) {
                      setState(() {
                        employee.status = value ?? EmployeeStatus.inactive;
                      });
                    },
                  ),
                  RadioListTile<EmployeeStatus>(
                    title: const Text('Active'),
                    value: EmployeeStatus.active,
                    groupValue: employee.status,
                    onChanged: (value) {
                      setState(() {
                        employee.status = value ?? EmployeeStatus.inactive;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AsyncDropdownFormField(
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
                    onChanged: (values) {
                      if (values == null || values.isEmpty) {
                        employee.payroll = null;
                        return;
                      }
                      employee.payroll = Payroll(
                        id: int.tryParse(values[0].getValueAsString()),
                        name: (values[0].getText() as Text).data ?? '',
                      );
                    },
                    selected: employee.payroll == null
                        ? null
                        : [
                            BsSelectBoxOption(
                                value: employee.payroll?.id,
                                text: Text(employee.payroll?.name ?? ''))
                          ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DatePicker(
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
                  DatePicker(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Kontak',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: employee.contactNumber,
                    onSaved: (newValue) {
                      employee.contactNumber = newValue.toString();
                    },
                    onChanged: (newValue) {
                      employee.contactNumber = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
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
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    label: const Text('Pilih gambar.'),
                    icon: const Icon(Icons.image),
                  ),
                  Visibility(
                      visible: employee.imageId != null,
                      child: SizedBox(
                        width: 400,
                        height: 300,
                        child: Image.network(_server.generateUrl(
                            'assets/${employee.imageId}', {}).toString()),
                      )),
                  Visibility(
                      visible: employee.imagePath != null,
                      child: SizedBox(
                        width: 400,
                        height: 300,
                        child: Image.network(employee.imagePath ?? ''),
                      )),
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
