import 'package:fe_pos/model/tag.dart';
import 'package:fe_pos/model/supplier.dart';
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

class SupplierFormPage extends StatefulWidget {
  final Supplier supplier;
  const SupplierFormPage({super.key, required this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage>
    with DefaultResponse, LoadingPopup {
  late Supplier supplier;
  late final Authorizer _setting;
  late final Server _server;
  late final TabManager _tabManager;
  final _formState = GlobalKey<FormState>();
  final flash = Flash();
  bool _showForm = true;
  @override
  void initState() {
    supplier = widget.supplier;
    _setting = context.read<Authorizer>();
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    if (!supplier.isNewRecord) {
      Future.delayed(Duration.zero, fetchSupplier);
    }
    super.initState();
  }

  void fetchSupplier() {
    setState(() {
      _showForm = false;
    });
    showLoadingPopup();
    supplier
        .refresh(
          _server,
          include: ['contact_numbers', 'account', 'taggings', 'tags'],
        )
        .then((isSuccess) {
          if (mounted && isSuccess) {
            setState(() {
              supplier;
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
    supplier.save(_server).then((result) {
      if (result) {
        setState(() {
          supplier;
        });
        flash.show(Text('Sukses Simpan'), .success);
        _tabManager.changeTabHeader(widget, 'Edit Supplier ${supplier.id}');
      } else {
        flash.showBanner(
          messageType: .error,
          title: 'Gagal Simpan Supplier',
          description: supplier.errors.join(','),
        );
      }
    });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Supplier "${supplier.name}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        supplier.reset();
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
      message: 'Apakah yakin duplikat Supplier "${supplier.name}"',
      onSubmit: () {
        supplier.id = null;
        for (final contactNumber in supplier.contactNumbers) {
          contactNumber.id = null;
        }
        for (final tagging in supplier.taggings) {
          tagging.id = null;
        }

        _tabManager.changeTabHeader(widget, 'Tambah Supplier');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Supplier');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        supplier = SupplierClass().initModel();
        _showForm = true;
      });
    });
  }

  void addContact() {
    setState(() {
      supplier.contactNumbers.add(ContactNumber());
    });
  }

  static const double tablePadding = 10;
  final double _width = 350;
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
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.name,
                            onChanged: (value) => supplier.name = value,
                            decoration: InputDecoration(
                              label: Text(
                                "${_setting.columnName('supplier', 'name')}*",
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: AsyncDropdownMultiple<Tag>(
                            textOnSearch: (tag) => tag.modelValue,
                            modelClass: TagClass(),
                            request: (queryRequest) {
                              queryRequest.include = ['tag_key'];
                              return TagClass().finds(_server, queryRequest);
                            },
                            label: Text('Tag'),
                            selecteds: supplier.tags,
                            onChanged: (tags) => supplier.setTags(tags),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.code,
                            onChanged: (value) => supplier.code = value,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'code'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.city,
                            onChanged: (value) => supplier.city = value,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'city'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.address,
                            onChanged: (value) => supplier.address = value,
                            keyboardType: .streetAddress,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'address'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.email,
                            onChanged: (value) => supplier.email = value,
                            keyboardType: .emailAddress,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'email'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.bank,
                            onChanged: (value) => supplier.bank = value,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'bank'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.bankAccountNumber,
                            onChanged: (value) =>
                                supplier.bankAccountNumber = value,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName(
                                  'supplier',
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
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.bankRegisterName,
                            onChanged: (value) =>
                                supplier.bankRegisterName = value,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName(
                                  'supplier',
                                  'bank_register_name',
                                ),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: TextFormField(
                            initialValue: supplier.description,
                            onChanged: (value) => supplier.description = value,
                            minLines: 3,
                            maxLines: 5,
                            keyboardType: .multiline,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('supplier', 'description'),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _width,
                          child: AsyncDropdown<Account>(
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
                              return AccountClass().finds(
                                _server,
                                queryRequest,
                              );
                            },
                            label: Text(
                              _setting.columnName('supplier', 'account'),
                            ),
                            selected: supplier.account,
                            onChanged: (model) => supplier.account = model,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: addContact,
                          child: Text('Tambah Kontak'),
                        ),
                        TableForm<ContactNumber>(
                          rows: supplier.contactNumbers,
                          columnSpacing: tablePadding,
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
                                    supplier.contactNumbers.removeAll();
                                  });
                                }
                              },
                              icon: Icon(Icons.delete),
                            ),
                            rowBuilder: (context, object, index) => IconButton(
                              onPressed: () {
                                setState(() {
                                  if (object.isNewRecord) {
                                    supplier.contactNumbers.remove(object);
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
                      visible: !supplier.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !supplier.isNewRecord,
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
