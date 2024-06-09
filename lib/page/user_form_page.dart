import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/user.dart';

import 'package:provider/provider.dart';

class UserFormPage extends StatefulWidget {
  final User user;
  const UserFormPage({super.key, required this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage>
    with AutomaticKeepAliveClientMixin, HistoryPopup {
  late Flash flash;
  late final Setting setting;
  final _formKey = GlobalKey<FormState>();
  User get user => widget.user;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    setting = context.read<Setting>();
    super.initState();
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'user',
        'id': user.id,
        'attributes': user.toJson(),
      }
    };
    Future request;
    if (user.id == null) {
      request = server.post('users', body: body);
    } else {
      request = server.put('users/${user.username}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          user.id = int.tryParse(data['id']);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(widget, 'Edit user ${user.username}');
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
      server.defaultErrorResponse(context: context, error: error);
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
                    visible: user.id != null,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                            onPressed: () =>
                                fetchHistoryByRecord('User', user.id),
                            label: const Text('Riwayat'),
                            icon: const Icon(Icons.history)),
                        ElevatedButton.icon(
                            onPressed: () => fetchHistoryByUser(user.id ?? 0),
                            label: const Text('Aktivitas User'),
                            icon: const Icon(Icons.history)),
                      ],
                    ),
                  ),
                  const Divider(),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    onSaved: (newValue) {
                      user.username = newValue.toString();
                    },
                    initialValue: user.username,
                    onChanged: (newValue) {
                      user.username = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: user.email,
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (newValue) {
                      user.email = newValue.toString();
                    },
                    validator: (newValue) {
                      if (newValue == null) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      user.email = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: AsyncDropdown<Role>(
                      converter: Role.fromJson,
                      key: const ValueKey('roleSelect'),
                      path: '/roles',
                      attributeKey: 'name',
                      label: const Text(
                        'Jabatan :',
                        style: labelStyle,
                      ),
                      onChanged: (role) {
                        user.role = role ?? Role();
                      },
                      textOnSearch: (role) => role.name,
                      selected: user.role,
                      validator: (value) {
                        if (user.role.id == null || value == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  Visibility(
                      visible: setting.canShow('user', 'status'),
                      child: Column(
                        children: [
                          const Text(
                            'Status:',
                            style: labelStyle,
                          ),
                          RadioListTile<UserStatus>(
                            title: const Text('Inactive'),
                            value: UserStatus.inactive,
                            groupValue: user.status,
                            onChanged: (value) {
                              setState(() {
                                user.status = value ?? UserStatus.inactive;
                              });
                            },
                          ),
                          RadioListTile<UserStatus>(
                            title: const Text('Active'),
                            value: UserStatus.active,
                            groupValue: user.status,
                            onChanged: (value) {
                              setState(() {
                                user.status = value ?? UserStatus.inactive;
                              });
                            },
                          ),
                        ],
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'password',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: user.password,
                    onSaved: (newValue) {
                      user.password = newValue.toString();
                    },
                    validator: (newValue) {
                      if ((newValue == null || newValue.trim().isEmpty) &&
                          user.id == null) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      user.password = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Konfirmasi password',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    initialValue: user.passwordConfirmation,
                    onSaved: (newValue) {
                      user.passwordConfirmation = newValue.toString();
                    },
                    validator: (newValue) {
                      if ((newValue == null || newValue.trim().isEmpty) &&
                          (user.password != null &&
                              user.password!.isNotEmpty)) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    onChanged: (newValue) {
                      user.passwordConfirmation = newValue.toString();
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
