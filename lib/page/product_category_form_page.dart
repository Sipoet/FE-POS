import 'package:collection/collection.dart';
import 'package:fe_pos/model/all_model.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/model/product_category.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:provider/provider.dart';

class ProductCategoryFormPage extends StatefulWidget {
  final ProductCategory productCategory;
  const ProductCategoryFormPage({super.key, required this.productCategory});

  @override
  State<ProductCategoryFormPage> createState() =>
      _ProductCategoryFormPageState();
}

class _ProductCategoryFormPageState extends State<ProductCategoryFormPage>
    with DefaultResponse, LoadingPopup, HistoryPopup {
  late ProductCategory productCategory;
  final _formState = GlobalKey<FormState>();
  final Map<int, FocusNode> _focusNodes = {};
  late final Server _server;
  late final TabManager _tabManager;
  final flash = Flash();
  bool _showForm = true;
  @override
  void initState() {
    productCategory = widget.productCategory;
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    super.initState();
    if (!productCategory.isNewRecord) {
      Future.delayed(Duration.zero, () {
        setState(() {
          _showForm = false;
        });
        showLoadingPopup();
        productCategory
            .refresh(_server, include: ['tag_keys', 'tag_key_groups'])
            .then(
              (result) => setState(() {
                productCategory.tagKeys;
              }),
            )
            .whenComplete(() {
              hideLoadingPopup();
              setState(() {
                _showForm = true;
              });
            });
      });
    }
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();
    productCategory
        .save(
          _server,
          includeAttributes: {
            'tag_key_groups_attributes': productCategory.tagKeyGroups
                .map((e) => e.asJson())
                .toList(),
          },
        )
        .then((result) {
          if (result) {
            setState(() {
              productCategory;
            });
            flash.show(Text('Sukses Simpan'), .success);
            _tabManager.changeTabHeader(
              widget,
              'Edit Kategori Produk ${productCategory.id}',
            );
          } else {
            debugPrint(productCategory.errors.join(','));
          }
        });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Kategori Produk "${productCategory.name}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        productCategory.reset();
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
      message:
          'Apakah yakin duplikat Kategori Produk "${productCategory.name}"',
      onSubmit: () {
        productCategory.id = null;
        for (final tagKeyGroup in productCategory.tagKeyGroups) {
          tagKeyGroup.id = null;
        }
        _tabManager.changeTabHeader(widget, 'Tambah Kategori Produk');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Kategori Produk');
    setState(() {
      _showForm = false;
    });
    Future.delayed(Durations.short1, () {
      productCategory = ProductCategoryClass().initModel();
      setState(() {
        _showForm = true;
      });
    });
  }

  void _addTagKey() {
    final tagKeyGroup = TagKeyGroup();
    _focusNodes[productCategory.tagKeyGroups.length] = FocusNode();
    setState(() {
      productCategory.tagKeyGroups.add(tagKeyGroup);
      Future.delayed(
        Duration.zero,
        () => _focusNodes[productCategory.tagKeyGroups.length - 1]
            ?.requestFocus(),
      );
    });
  }

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
              children: [
                Expanded(
                  child: VerticalBodyScroll(
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: .start,
                      children: [
                        Visibility(
                          visible: !productCategory.isNewRecord,
                          child: ElevatedButton.icon(
                            onPressed: () => fetchHistoryByRecord(
                              'Kategori Produk',
                              productCategory.id,
                            ),
                            label: const Text('Riwayat'),
                            icon: const Icon(Icons.history),
                          ),
                        ),
                        TextFormField(
                          initialValue: productCategory.name,
                          onChanged: (value) => productCategory.name = value,
                          decoration: InputDecoration(
                            label: Text(
                              'Nama*',
                              style: DefaultResponse.labelStyle,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                        ),
                        AsyncDropdown<ProductCategory>(
                          textOnSearch: (e) => e.name,
                          label: Text('Parent'),
                          selected: productCategory.parent,
                          modelClass: ProductCategoryClass(),
                          onChanged: (model) => productCategory.parent = model,
                        ),
                        AsyncDropdownMultiple<TagKey>(
                          textOnSearch: (e) => e.name,
                          label: Text('Kunci Deskripsi'),
                          selecteds: productCategory.tagKeys,
                          modelClass: TagKeyClass(),
                          onChanged: (models) =>
                              productCategory.setTagKeys(models),
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
                    if (!productCategory.isNewRecord)
                      ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    if (!productCategory.isNewRecord)
                      ElevatedButton(
                        onPressed: _duplicateRecord,
                        child: Text('Menduplikasi'),
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
