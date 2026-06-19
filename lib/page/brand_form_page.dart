import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrandFormPage extends StatefulWidget {
  final Brand brand;
  const BrandFormPage({super.key, required this.brand});

  @override
  State<BrandFormPage> createState() => _BrandFormPageState();
}

class _BrandFormPageState extends State<BrandFormPage>
    with DefaultResponse, LoadingPopup {
  late Brand brand;
  final _formState = GlobalKey<FormState>();
  late final Setting _setting;
  late final Server _server;
  late final TabManager _tabManager;
  final flash = Flash();
  bool _showForm = true;
  @override
  void initState() {
    brand = widget.brand;
    _tabManager = context.read<TabManager>();
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    super.initState();
    if (brand.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchBrand);
    }
  }

  void fetchBrand() {
    showLoadingPopup();
    brand.refresh(_server).whenComplete(() => hideLoadingPopup());
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();
    brand.save(_server).then((result) {
      if (result) {
        setState(() {
          brand;
        });
        flash.show(Text('Sukses Simpan'), .success);
        _tabManager.changeTabHeader(widget, 'Edit Merek ${brand.id}');
      } else {
        flash.showBanner(
          messageType: .error,
          title: 'Gagal Simpan Merek',
          description: brand.errors.join(','),
        );
      }
    });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Merek "${brand.name}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        brand.reset();
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
      message: 'Apakah yakin duplikat Merek "${brand.name}"',
      onSubmit: () {
        brand.id = null;
        _tabManager.changeTabHeader(widget, 'Tambah Merek');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Merek');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        brand = BrandClass().initModel();
        _showForm = true;
      });
    });
  }

  final width = 350.0;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: .all(10),
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
                          width: width,
                          child: TextFormField(
                            initialValue: brand.name,
                            onChanged: (value) => brand.name = value,
                            decoration: InputDecoration(
                              label: Text(_setting.columnName('brand', 'name')),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isNotEmpty == false) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: TextFormField(
                            initialValue: brand.description,
                            onChanged: (value) => brand.description = value,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              label: Text(
                                _setting.columnName('brand', 'description'),
                              ),
                              border: OutlineInputBorder(),
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
                      visible: !brand.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !brand.isNewRecord,
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
