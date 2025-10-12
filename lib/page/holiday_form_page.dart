import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/holiday.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_form_field.dart';

import 'package:provider/provider.dart';

class HolidayFormPage extends StatefulWidget {
  final Holiday holiday;
  const HolidayFormPage({super.key, required this.holiday});

  @override
  State<HolidayFormPage> createState() => _HolidayFormPageState();
}

class _HolidayFormPageState extends State<HolidayFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        DefaultResponse {
  late Flash flash;
  final _formKey = GlobalKey<FormState>();
  Holiday get holiday => widget.holiday;
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
        'type': 'holiday',
        'attributes': holiday.toJson(),
      }
    };

    if (holiday.id == null) {
      request = _server.post('holidays', body: body);
    } else {
      request = _server.put('holidays/${holiday.id}', body: body);
    }
    request?.then((response) {
      request = null;
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          holiday.setFromJson(data, included: response.data['included'] ?? []);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Libur Karyawan ${holiday.id}');
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
                    visible: holiday.id != null,
                    child: ElevatedButton.icon(
                        onPressed: () =>
                            fetchHistoryByRecord('Holiday', holiday.id),
                        label: const Text('Riwayat'),
                        icon: const Icon(Icons.history)),
                  ),
                  const Divider(),
                  Visibility(
                    visible: setting.canShow('holiday', 'date'),
                    child: DateFormField(
                        label: const Text(
                          'Tanggal',
                          style: labelStyle,
                        ),
                        datePickerOnly: true,
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          holiday.date = Date.parsingDateTime(newValue);
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
                          holiday.date = Date.parsingDateTime(newValue);
                        },
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 31)),
                        initialValue: holiday.date),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownMenu<Religion>(
                    width: 200,
                    menuHeight: 200,
                    label: Text('Agama'),
                    initialSelection: holiday.religion,
                    onSelected: (value) =>
                        holiday.religion = value ?? holiday.religion,
                    dropdownMenuEntries: Religion.values
                        .map<DropdownMenuEntry<Religion>>((religion) =>
                            DropdownMenuEntry<Religion>(
                                value: religion, label: religion.humanize()))
                        .toList(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: setting.canShow('holiday', 'description'),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          label: Text(
                            'Deskripsi',
                            style: labelStyle,
                          ),
                          border: OutlineInputBorder()),
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (value) => holiday.description = value,
                      initialValue: holiday.description,
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
