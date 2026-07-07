import 'package:fe_pos/model/forwarder.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/enum_dropdown.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/flash.dart';

class ForwarderFormPage extends StatefulWidget {
  final Forwarder forwarder;
  const ForwarderFormPage({super.key, required this.forwarder});

  @override
  State<ForwarderFormPage> createState() => _ForwarderFormPageState();
}

class _ForwarderFormPageState extends State<ForwarderFormPage>
    with DefaultResponse, LoadingPopup {
  late Forwarder forwarder;
  late final Authorizer _setting;
  late final Server _server;
  late final TabManager _tabManager;
  final _formState = GlobalKey<FormState>();
  final flash = Flash();
  bool _showForm = true;
  @override
  void initState() {
    forwarder = widget.forwarder;
    _setting = context.read<Authorizer>();
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    if (!forwarder.isNewRecord) {
      Future.delayed(Duration.zero, fetchForwarder);
    }
    super.initState();
  }

  void fetchForwarder() {
    setState(() {
      _showForm = false;
    });
    showLoadingPopup();
    forwarder
        .refresh(_server, include: ['contact_numbers', 'account'])
        .then((isSuccess) {
          if (mounted && isSuccess) {
            setState(() {
              forwarder;
            });
          }
        })
        .whenComplete(() {
          hideLoadingPopup();
          setState(() {
            _showForm = true;
          });
        });
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();
    forwarder.save(_server).then((result) {
      if (result) {
        setState(() {
          forwarder;
        });
        flash.show(Text('Sukses Simpan'), .success);
        _tabManager.changeTabHeader(widget, 'Edit Forwarder ${forwarder.id}');
      } else {
        flash.showBanner(
          messageType: .error,
          title: 'Gagal Simpan Forwarder',
          description: forwarder.errors.join(','),
        );
      }
    });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Forwarder "${forwarder.name}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        forwarder.reset();
        Future.delayed(Durations.short1, () {
          setState(() {
            _showForm = true;
          });
        });
      },
    );
  }

  void _duplicateRecord() {
    showConfirmDialog(
      message: 'Apakah yakin duplikat Forwarder "${forwarder.name}"',
      onSubmit: () {
        forwarder.id = null;
        for (final contactNumber in forwarder.contactNumbers) {
          contactNumber.id = null;
        }
        for (final tagging in forwarder.taggings) {
          tagging.id = null;
        }

        _tabManager.changeTabHeader(widget, 'Tambah Forwarder');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Forwarder');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        forwarder = ForwarderClass().initModel();
        _showForm = true;
      });
    });
  }

  void addContact() {
    setState(() {
      forwarder.contactNumbers.add(ContactNumber());
    });
  }

  static const double tablePadding = 10;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(10),
        child: Form(
          key: _formState,
          autovalidateMode: .onUnfocus,
          child: Visibility(
            visible: _showForm,
            child: Column(
              mainAxisSize: .max,
              children: [
                Expanded(
                  child: VerticalBodyScroll(
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: .start,
                      children: [
                        TextFormField(
                          initialValue: forwarder.name,
                          onChanged: (value) => forwarder.name = value,
                          decoration: InputDecoration(
                            label: Text(
                              "${_setting.columnName('forwarder', 'name')}*",
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: forwarder.city,
                          onChanged: (value) => forwarder.city = value,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName('forwarder', 'city'),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: forwarder.address,
                          onChanged: (value) => forwarder.address = value,
                          keyboardType: .streetAddress,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName('forwarder', 'address'),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: forwarder.email,
                          onChanged: (value) => forwarder.email = value,
                          keyboardType: .emailAddress,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName('forwarder', 'email'),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        TextFormField(
                          initialValue: forwarder.bank,
                          onChanged: (value) => forwarder.bank = value,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName('forwarder', 'bank'),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: forwarder.bankAccountNumber,
                          onChanged: (value) =>
                              forwarder.bankAccountNumber = value,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName(
                                'forwarder',
                                'bank_account_number',
                              ),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            CustomNumberInputFormatter(
                              formatType: .bankAccount,
                            ),
                          ],
                          keyboardType: .number,
                        ),
                        TextFormField(
                          initialValue: forwarder.bankRegisterName,
                          onChanged: (value) =>
                              forwarder.bankRegisterName = value,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName(
                                'forwarder',
                                'bank_register_name',
                              ),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: forwarder.description,
                          onChanged: (value) => forwarder.description = value,
                          minLines: 3,
                          maxLines: 5,
                          keyboardType: .multiline,
                          decoration: InputDecoration(
                            label: Text(
                              _setting.columnName('forwarder', 'description'),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        AsyncDropdown<Account>(
                          textOnSearch: (account) =>
                              '${account.name} (${account.accountType})',
                          modelClass: AccountClass(),
                          request: (queryRequest) {
                            queryRequest.filters.add(
                              ComparisonFilterData(
                                key: 'is_header',
                                value: false,
                              ),
                            );
                            return AccountClass().finds(_server, queryRequest);
                          },
                          label: Text(
                            _setting.columnName('forwarder', 'account'),
                          ),
                          selected: forwarder.account,
                          onChanged: (model) => forwarder.account = model,
                        ),
                        ElevatedButton(
                          onPressed: addContact,
                          child: Text('Tambah Kontak'),
                        ),
                        TableForm<ContactNumber>(
                          rows: forwarder.contactNumbers,
                          columnSpacing: .all(tablePadding),
                          columns: [
                            TableFormColumn(
                              title: 'Nama',
                              desktopWidth: FixedColumnWidth(200),
                              headerBuilder: (context) =>
                                  Text('Nama', style: TextFormatter.labelStyle),
                              rowBuilder: (context, contactNumber, index) =>
                                  TextFormField(
                                    initialValue: contactNumber.name,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        contactNumber.name = value,
                                  ),
                            ),
                            TableFormColumn(
                              title: 'Platform',
                              headerBuilder: (context) => Text(
                                'Platform',
                                style: TextFormatter.labelStyle,
                              ),
                              rowBuilder: (context, contactNumber, index) =>
                                  EnumDropdown<ContactPlatform>(
                                    width: 200,
                                    initialSelection: contactNumber.platform,
                                    values: ContactPlatform.values,
                                    onChanged: (value) => setState(() {
                                      contactNumber.platform =
                                          value ?? contactNumber.platform;
                                    }),
                                  ),
                            ),
                            TableFormColumn(
                              title: 'Value',
                              headerBuilder: (context) => Text(
                                'Value',
                                style: TextFormatter.labelStyle,
                              ),
                              rowBuilder: (context, contactNumber, index) =>
                                  Visibility(
                                    replacement: TextFormField(
                                      initialValue: contactNumber.value,
                                      keyboardType: .url,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'https://xxxxx',
                                      ),
                                      onChanged: (value) =>
                                          contactNumber.value = value,
                                    ),
                                    visible: [
                                      ContactPlatform.fax,
                                      ContactPlatform.tel,
                                      ContactPlatform.whatsapp,
                                      ContactPlatform.telegram,
                                    ].contains(contactNumber.platform),
                                    child: TextFormField(
                                      initialValue: contactNumber.value,
                                      keyboardType: .phone,
                                      inputFormatters: [
                                        CustomNumberInputFormatter(
                                          maxLength: 13,
                                          formatType: .phoneNumber,
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '62X XXX XXX XXX',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) =>
                                          contactNumber.value = value,
                                    ),
                                  ),
                            ),
                          ],
                          actionColumn: TableFormColumn(
                            desktopWidth: FixedColumnWidth(60),
                            headerBuilder: (context) => IconButton(
                              onPressed: () async {
                                if (await showConfirmDialog2(
                                  message: 'Apakah yakin Hapus Semua Kontak?',
                                )) {
                                  setState(() {
                                    forwarder.contactNumbers.removeAll();
                                  });
                                }
                              },
                              icon: Icon(Icons.delete),
                            ),
                            rowBuilder: (context, object, index) => IconButton(
                              onPressed: () {
                                setState(() {
                                  if (object.isNewRecord) {
                                    forwarder.contactNumbers.remove(object);
                                  } else {
                                    object.flagDestroy();
                                  }
                                });
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Wrap(
                  runSpacing: 15,
                  spacing: 15,
                  children: [
                    ElevatedButton(
                      onPressed: _saveRecord,
                      child: Text('Simpan'),
                    ),
                    ElevatedButton(
                      onPressed: _resetRecord,
                      child: Text('Reset'),
                    ),
                    Visibility(
                      visible: !forwarder.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !forwarder.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _duplicateRecord,
                        child: Text('Menduplikasi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
