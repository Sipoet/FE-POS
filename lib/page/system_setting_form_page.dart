import 'dart:convert';

import 'package:fe_pos/model/system_setting.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/time_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SystemSettingFormPage extends StatefulWidget {
  final SystemSetting systemSetting;
  const SystemSettingFormPage({super.key, required this.systemSetting});

  @override
  State<SystemSettingFormPage> createState() => _SystemSettingFormPageState();
}

class _SystemSettingFormPageState extends State<SystemSettingFormPage>
    with LoadingPopup, DefaultResponse {
  SystemSetting get systemSetting => widget.systemSetting;
  late final Setting _setting;
  late final Flash _flash;
  late final Server _server;
  final Map<String, TextEditingController> _controller = {};

  @override
  void initState() {
    _flash = Flash();
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    systemSetting.toMap().forEach((key, value) {
      _controller[key] = TextEditingController(text: value.toString());
    });
    super.initState();
    if (systemSetting.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchSystemSetting);
    }
  }

  void fetchSystemSetting() {
    showLoadingPopup();
    _server
        .get('systemSettings/${systemSetting.id}')
        .then((response) {
          if (mounted && response.statusCode == 200) {
            systemSetting.setFromJson(
              response.data['data'],
              included: response.data['included'] ?? [],
            );
          }
        })
        .whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            initialValue: systemSetting.key,
            readOnly: true,
            decoration: InputDecoration(
              label: Text(_setting.columnName('systemSetting', 'key_name')),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownMenu<SettingValueType>(
            initialSelection: systemSetting.valueType,
            onSelected: (value) =>
                systemSetting.valueType = value ?? systemSetting.valueType,
            enabled: systemSetting.isNewRecord,
            dropdownMenuEntries: SettingValueType.values
                .map<DropdownMenuEntry<SettingValueType>>(
                  (value) => DropdownMenuEntry<SettingValueType>(
                    value: value,
                    label: value.humanize(),
                  ),
                )
                .toList(),
            label: Text(_setting.columnName('systemSetting', 'value_type')),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: [
              SettingValueType.string,
              SettingValueType.json,
            ].contains(systemSetting.valueType),
            child: TextFormField(
              initialValue: systemSetting.value.toString(),
              minLines: 1,
              maxLines: 5,
              onChanged: (value) {
                if (systemSetting.valueType == SettingValueType.string) {
                  systemSetting.value = value;
                } else if (systemSetting.valueType == SettingValueType.json) {
                  try {
                    systemSetting.value = jsonDecode(value);
                  } catch (e) {
                    systemSetting.value = null;
                  }
                }
              },
              decoration: InputDecoration(
                label: Text(_setting.columnName('systemSetting', 'value')),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Visibility(
            visible: systemSetting.valueType == SettingValueType.number,
            child: NumberFormField<double>(
              initialValue: systemSetting.value is num
                  ? double.tryParse(systemSetting.value.toString())
                  : null,
              onChanged: (value) => systemSetting.value = value,
              label: Text(_setting.columnName('systemSetting', 'value')),
            ),
          ),
          Visibility(
            visible: systemSetting.valueType == SettingValueType.date,
            child: DateFormField(
              initialValue: systemSetting.value is Date
                  ? systemSetting.value.toDateTime()
                  : null,
              dateType: DateType(),
              onChanged: (value) => systemSetting.value = value == null
                  ? null
                  : Date.parsingDateTime(value),
              label: Text(_setting.columnName('systemSetting', 'value')),
            ),
          ),
          Visibility(
            visible: systemSetting.valueType == SettingValueType.datetime,
            child: DateFormField(
              initialValue: systemSetting.value is DateTime
                  ? systemSetting.value
                  : null,
              onChanged: (value) => systemSetting.value = value,
              label: Text(_setting.columnName('systemSetting', 'value')),
            ),
          ),
          Visibility(
            visible: systemSetting.valueType == SettingValueType.time,
            child: TimeFormField(
              initialValue: systemSetting.value is TimeOfDay
                  ? systemSetting.value
                  : null,
              onChanged: (value) => systemSetting.value = value,
              label: Text(_setting.columnName('systemSetting', 'value')),
            ),
          ),
          Visibility(
            visible: systemSetting.valueType == SettingValueType.boolean,
            child: CheckboxListTile(
              value: systemSetting.value is bool ? systemSetting.value : null,
              tristate: true,
              onChanged: (value) => setState(() {
                systemSetting.value = value;
              }),
              title: Text(_setting.columnName('systemSetting', 'value')),
            ),
          ),
          const SizedBox(height: 10),
          AsyncDropdown(
            label: Text("User"),
            allowClear: true,
            selected: systemSetting.user,
            onChanged: (model) => systemSetting.user = model,
            textOnSearch: (record) => record.username,
            modelClass: UserClass(),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _submit, child: Text('Submit')),
        ],
      ),
    );
  }

  void _submit() {
    showLoadingPopup();
    final server = context.read<Server>();
    if (systemSetting.isNewRecord) return;
    final params = {
      'data': {
        'id': systemSetting.id,
        'type': 'system_setting',
        'attributes': systemSetting.toJson(),
      },
    };
    server
        .put('system_settings/${systemSetting.id}', body: params)
        .then((response) {
          if (mounted && response.statusCode == 200) {
            setState(() {
              systemSetting.setFromJson(
                response.data['data'],
                included: response.data['included'] ?? [],
              );
            });
            _flash.show(Text('Sukses simpan'), ToastificationType.success);
          } else {
            _flash.show(Text('Gagal simpan'), ToastificationType.error);
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }
}
