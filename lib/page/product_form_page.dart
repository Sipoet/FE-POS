import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/tag_key.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/image_carousel.dart';
import 'package:fe_pos/widget/image_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/product.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';

class ProductFormPage extends StatefulWidget {
  final Product product;
  const ProductFormPage({required this.product, super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse, LoadingPopup {
  late Product product;
  late final Setting _setting;
  late final Server _server;
  late final TabManager _tabManager;
  late final ImageCarouselController controller;
  final _formState = GlobalKey<FormState>();
  final flash = Flash();
  bool _showForm = true;
  List<ProductTag> productTags = [];
  List<bool> panelPool = List.generate(2, (e) => false);

  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    product = widget.product;
    controller = ImageCarouselController(images: product.images);
    super.initState();
    if (!product.isNewRecord) {
      Future.delayed(Duration.zero, fetchProduct);
    }
  }

  @override
  bool get wantKeepAlive => true;

  void fetchProduct() {
    showLoadingPopup();
    setState(() {
      _showForm = false;
    });
    product
        .refresh(
          _server,
          include: [
            'taggings',
            'tags',
            'product_category',
            'supplier',
            'brand',
            'stock_account',
            'images',
          ],
        )
        .then((result) {
          setState(() {
            controller.setImages(product.images);
            productTags = product.tags
                .map<ProductTag>(
                  (tag) => ProductTag(tagKey: tag.tagKey, tag: tag),
                )
                .toList();
          });
        })
        .whenComplete(() {
          setState(() {
            _showForm = true;
          });
          hideLoadingPopup();
        });
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();

    product.setTags(productTags.map((e) => e.tag!).toList());

    product
        .save(
          _server,
          contentType: .multipartForm,
          includeAttributes: {
            'taggings_attributes': product.taggings
                .map((e) => e.asJson())
                .toList(),
          },
        )
        .then((result) {
          if (result) {
            setState(() {
              product.images;
            });
            flash.show(Text('Sukses Simpan'), .success);
            _tabManager.changeTabHeader(widget, 'Edit Supplier ${product.id}');
          } else {
            flash.showBanner(
              messageType: .error,
              title: 'Gagal Simpan produk',
              description: product.errors.join(','),
            );
          }
        });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Produk "${product.id}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        product.reset();
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
      message: 'Apakah yakin duplikat Produk "${product.id}"',
      onSubmit: () {
        product.id = null;
        product.barcode = '';
        for (final tagging in product.taggings) {
          tagging.id = null;
        }
        product.images.clear();
        controller.clearImages();

        _tabManager.changeTabHeader(widget, 'Tambah Produk');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Produk');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        product = ProductClass().initModel();
        controller.clearImages();
        _showForm = true;
      });
    });
  }

  void setTagKeys(List<TagKey> newTagKeys) {
    final tagKeyIds = newTagKeys.map((e) => e.id).toList();
    for (final productTag in productTags) {
      if (productTag.tagKeyId == null) {
        productTags.remove(productTag);
      }
      if (tagKeyIds.contains(productTag.tagKeyId)) {
        tagKeyIds.remove(productTag.tagKeyId);
      }
    }
    for (final tagKeyId in tagKeyIds) {
      final tagKey = newTagKeys.firstWhere((e) => e.id == tagKeyId);
      productTags.add(ProductTag(tagKey: tagKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          runSpacing: 10,
                          spacing: 10,
                          children: [
                            ImageCarousel(
                              controller: controller,
                              allowClear: true,
                              onRemoved: (image) => setState(() {
                                if (image.isAttached) {
                                  image.flagDestroy();
                                  product.images;
                                } else {
                                  product.images.remove(image);
                                }
                              }),
                            ),
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: ImageFormField(
                                maxFiles: 5,
                                onChanged: (images) {
                                  setState(() {
                                    controller.addImages(images);
                                    product.images.addAll(images);
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                initialValue: product.supplierProductCode,
                                onChanged: (value) =>
                                    product.supplierProductCode = value,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  label: Text(
                                    "${_setting.columnName('product', 'supplier_product_code')}*",
                                    style: DefaultResponse.labelStyle,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                initialValue: product.baseUom,
                                onChanged: (value) => product.baseUom = value,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  label: Text(
                                    "${_setting.columnName('product', 'base_uom')}*",
                                    style: DefaultResponse.labelStyle,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: AsyncDropdown<ProductCategory>(
                                textOnSearch: (model) =>
                                    "${model.name} -  ${model.description}",
                                textOnSelected: (model) => model.name,
                                validator: (model) {
                                  if (model == null) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                                selected: product.productCategory,
                                request: (queryRequest) {
                                  queryRequest.include = [
                                    'tag_keys',
                                    'tag_key_groups',
                                  ];
                                  return ProductCategoryClass().finds(
                                    _server,
                                    queryRequest,
                                  );
                                },
                                allowClear: false,
                                label: Text(
                                  "${_setting.columnName('product', 'product_category')}*",
                                  style: DefaultResponse.labelStyle,
                                ),
                                isDense: true,
                                onChanged: (model) => setState(() {
                                  product.productCategory = model;
                                  setTagKeys(model?.tagKeys ?? []);
                                }),
                                modelClass: ProductCategoryClass(),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: AsyncDropdown<Brand>(
                                validator: (model) {
                                  if (model == null) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                                textOnSearch: (model) =>
                                    "${model.name} -  ${model.description}",
                                textOnSelected: (model) => model.name,
                                label: Text(
                                  "${_setting.columnName('product', 'brand')}*",
                                  style: DefaultResponse.labelStyle,
                                ),
                                allowClear: false,
                                isDense: true,
                                selected: product.brand,
                                onChanged: (brand) => product.brand = brand,
                                modelClass: BrandClass(),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                keyboardType: TextInputType.text,
                                onChanged: (value) => product.barcode = value,
                                initialValue: product.barcode,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                  UpperCaseTextFormatter(),
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[0-9A-Z]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  label: Text(
                                    _setting.columnName('product', 'barcode'),
                                    style: DefaultResponse.labelStyle,
                                  ),
                                  hintText: 'Auto',
                                  helperText:
                                      'hanya boleh diisi huruf dan angka',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: CheckboxListTile(
                                title: Text('Pakai Batch di Barcode?'),
                                value: product.barcodeUsingBatch,
                                onChanged: (value) => setState(() {
                                  product.barcodeUsingBatch = value!;
                                }),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: AsyncDropdown<Supplier>(
                                textOnSearch: (model) => " ${model.name}",
                                label: Text(
                                  _setting.columnName('product', 'supplier'),
                                  style: DefaultResponse.labelStyle,
                                ),
                                allowClear: false,
                                isDense: true,
                                selected: product.supplier,
                                onChanged: (model) => product.supplier = model,
                                modelClass: SupplierClass(),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: AsyncDropdown<Account>(
                                textOnSearch: (model) => " ${model.name}",
                                label: Text(
                                  "${_setting.columnName('product', 'stock_account')}*",
                                  style: DefaultResponse.labelStyle,
                                ),
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
                                validator: (model) {
                                  if (model == null) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                                allowClear: false,
                                isDense: true,
                                selected: product.stockAccount,
                                onChanged: (model) =>
                                    product.stockAccount = model,
                                modelClass: AccountClass(),
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                initialValue: product.description,
                                keyboardType: TextInputType.multiline,
                                onChanged: (value) =>
                                    product.description = value,
                                minLines: 3,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  label: Text(
                                    _setting.columnName(
                                      'product',
                                      'description',
                                    ),
                                    style: DefaultResponse.labelStyle,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              panelPool[index] = isExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              canTapOnHeader: true,
                              isExpanded: panelPool[0],
                              headerBuilder: (context, isExpanded) => Row(
                                spacing: 10,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Text(
                                      'Detail Produk',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                  ),
                                  if (panelPool[0])
                                    IconButton.outlined(
                                      onPressed: () => setState(() {
                                        productTags.insert(0, ProductTag());
                                      }),
                                      icon: Icon(Icons.add),
                                    ),
                                ],
                              ),
                              body: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TableForm<ProductTag>(
                                  rows: productTags,
                                  columns: [
                                    TableFormColumn<ProductTag>(
                                      name: 'tag_key',
                                      title: 'Kategori',
                                      headerBuilder: (context) => Text(
                                        'Kategori',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, productTag) {
                                        return AsyncDropdown<TagKey>(
                                          validator: (model) {
                                            if (model == null) {
                                              return 'harus diisi';
                                            }
                                            return null;
                                          },
                                          onChanged: (tagKey) {
                                            productTag.tagKey = tagKey;
                                            if (productTag.tag?.tagKeyId !=
                                                tagKey?.id) {
                                              setState(() {
                                                productTag.isNewTag = true;
                                                productTag.tag = null;
                                              });
                                              Future.delayed(
                                                Durations.short1,
                                                () {
                                                  setState(() {
                                                    productTag.isNewTag = false;
                                                  });
                                                },
                                              );
                                            }
                                          },
                                          textOnSearch: (model) => model.name,
                                          isDense: true,
                                          allowClear: false,
                                          selected: productTag.tagKey,
                                          modelClass: TagKeyClass(),
                                        );
                                      },
                                    ),
                                    TableFormColumn<ProductTag>(
                                      name: 'tag',
                                      title: 'Value',
                                      headerBuilder: (context) => Text(
                                        'Value',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, productTag) => Visibility(
                                        visible: productTag.isNewTag,
                                        replacement: Row(
                                          spacing: 20,
                                          children: [
                                            Expanded(
                                              child: AsyncDropdown<Tag>(
                                                selected: productTag.tag,
                                                allowClear: false,
                                                validator: (model) {
                                                  if (model == null) {
                                                    return 'harus diisi';
                                                  }
                                                  return null;
                                                },
                                                textOnSearch: (model) =>
                                                    model.value,
                                                modelClass: TagClass(),
                                                request: (queryRequest) {
                                                  queryRequest.filters.add(
                                                    ComparisonFilterData(
                                                      key: 'tag_key_id',
                                                      value:
                                                          productTag.tagKeyId,
                                                    ),
                                                  );
                                                  return TagClass().finds(
                                                    _server,
                                                    queryRequest,
                                                  );
                                                },
                                                isDense: true,
                                                onChanged: (tag) =>
                                                    setState(() {
                                                      productTag.tag = tag;
                                                      if (tag != null &&
                                                          productTag.tagKeyId !=
                                                              tag.tagKeyId) {
                                                        productTag.tagKey =
                                                            tag.tagKey;
                                                      }
                                                    }),
                                              ),
                                            ),
                                            Visibility(
                                              visible:
                                                  productTag.tagKey != null,
                                              child: ElevatedButton(
                                                onPressed: () => setState(() {
                                                  productTag.isNewTag =
                                                      !productTag.isNewTag;
                                                }),
                                                child: Text('Tag baru'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          spacing: 20,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .singleLineFormatter,
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'[A-Za-z0-9\s]'),
                                                  ),
                                                ],
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'harus diisi';
                                                  }
                                                  return null;
                                                },
                                                forceErrorText:
                                                    productTag
                                                            .tag
                                                            ?.errors
                                                            .isEmpty ==
                                                        true
                                                    ? null
                                                    : productTag.tag?.errors
                                                          .join(','),
                                                onChanged: (value) {
                                                  productTag.newTagValue =
                                                      value;
                                                },
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _createTag(productTag),
                                              icon: Icon(Icons.check),
                                            ),
                                            IconButton(
                                              onPressed: () => setState(() {
                                                productTag.isNewTag = false;
                                              }),
                                              icon: Icon(Icons.cancel),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TableFormColumn<ProductTag>(
                                      name: 'action',
                                      title: '',
                                      desktopWidth: FixedColumnWidth(80),
                                      headerBuilder: (context) => IconButton(
                                        onPressed: () => showConfirmDialog(
                                          message: 'Apakah yakin hapus semua?',
                                          onSubmit: () => setState(() {
                                            productTags.clear();
                                          }),
                                        ),
                                        icon: Icon(Icons.delete),
                                      ),
                                      rowBuilder: (context, productTag) =>
                                          IconButton(
                                            onPressed: () => setState(() {
                                              productTags.remove(productTag);
                                            }),
                                            icon: Icon(Icons.delete),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ExpansionPanel(
                              isExpanded: panelPool[1],
                              canTapOnHeader: true,
                              headerBuilder: (context, isExpanded) => Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  'SKU',
                                  style: DefaultResponse.labelStyle,
                                ),
                              ),
                              body: SizedBox(
                                height: bodyScreenHeight,
                                child: CustomAsyncDataTable<StockKeepingUnit>(
                                  fetchData: (QueryRequest request) {
                                    if (product.isNewRecord) {
                                      return Future.value(
                                        DataTableResponse<StockKeepingUnit>(
                                          totalPage: 1,
                                          models: [],
                                        ),
                                      );
                                    }
                                    request.filters.add(
                                      ComparisonFilterData(
                                        key: 'product_id',
                                        value: product.id.toString(),
                                      ),
                                    );
                                    return StockKeepingUnitClass()
                                        .finds(_server, request)
                                        .then(
                                          (
                                            queryResponse,
                                          ) => DataTableResponse<StockKeepingUnit>(
                                            totalPage:
                                                queryResponse
                                                    .metadata['total_pages'] ??
                                                1,
                                            models: queryResponse.models,
                                          ),
                                        );
                                  },
                                  columns: [
                                    TableColumn(
                                      clientWidth: 200,
                                      name: 'barcode',
                                      humanizeName: 'Barcode',
                                    ),
                                    TableColumn(
                                      clientWidth: 150,
                                      name: 'prodDate',
                                      type: TableColumnType.date,
                                      humanizeName: 'Tanggal Produksi',
                                    ),
                                    TableColumn(
                                      clientWidth: 200,
                                      name: 'description',
                                      humanizeName: 'Deskripsi',
                                    ),
                                    TableColumn(
                                      clientWidth: 120,
                                      name: 'quantity',
                                      type: TableColumnType.double,
                                      humanizeName: 'Jumlah',
                                    ),
                                    TableColumn(
                                      clientWidth: 120,
                                      name: 'uom',
                                      humanizeName: 'Satuan',
                                    ),
                                    TableColumn(
                                      clientWidth: 180,
                                      name: 'cogs',
                                      type: TableColumnType.money,
                                      humanizeName: 'HPP',
                                    ),
                                    TableColumn(
                                      clientWidth: 180,
                                      name: 'sell_price',
                                      type: TableColumnType.money,
                                      humanizeName: 'Harga Jual',
                                    ),
                                    TableColumn(
                                      clientWidth: 150,
                                      name: 'expired_date',
                                      type: TableColumnType.date,
                                      humanizeName: 'Tanggal Expired',
                                    ),
                                  ],
                                  showFilter: true,
                                  showSummary: true,
                                ),
                              ),
                            ),
                          ],
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
                      visible: !product.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !product.isNewRecord,
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

  void _createTag(ProductTag productTag) {
    if (productTag.newTagValue?.isEmpty == true) {
      return;
    }
    Tag tag = Tag(tagKey: productTag.tagKey, value: productTag.newTagValue!);
    tag.save(_server).then((isSuccess) {
      if (isSuccess) {
        setState(() {
          productTag.tag = tag;
          productTag.isNewTag = false;
        });
      } else {
        setState(() {
          tag.errors;
        });
      }
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ProductTag {
  TagKey? tagKey;
  Tag? tag;
  bool isNewTag;
  String? newTagValue;
  ProductTag({this.tag, this.tagKey, this.isNewTag = false, this.newTagValue});

  int? get tagKeyId => tagKey?.id;
  int? get tagId => tag?.id;
}
