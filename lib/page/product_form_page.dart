import 'package:fe_pos/model/product_measurement.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/tag_key.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/image_carousel.dart';
import 'package:fe_pos/widget/image_form_field.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/stock_sell_price_form_dialog.dart';
import 'package:fe_pos/widget/number_form_field.dart';
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
  Map<int, bool> panelPool = {};

  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    product = widget.product;
    controller = ImageCarouselController(images: product.images.toList());
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
            'product_measurements',
            'product_measurements.uom',
            'base_uom',
          ],
        )
        .then((result) {
          setState(() {
            controller.setImages(product.images.toList());
            productTags = product.tags
                .map<ProductTag>(
                  (tag) => ProductTag(tagKey: tag.tagKey, tag: tag),
                )
                .toList();
          });
          refreshSku();
        })
        .whenComplete(() {
          setState(() {
            _showForm = true;
          });
          hideLoadingPopup();
        });
  }

  void refreshSku() {
    if (!_setting.isAuthorize('stock_keeping_units', 'read')) {
      return;
    }
    final queryRequest = QueryRequest(
      include: ['supplier', 'stock_sell_prices', 'stock_sell_prices.uom'],
      filters: [ComparisonFilterData(key: 'product', value: product.id)],
    );
    StockKeepingUnitClass().finds(_server, queryRequest).then(((result) {
      setState(() {
        product.stockKeepingUnits = result.models;
      });
    }));
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();

    product.setTags(productTags.map((e) => e.tag!).toList());

    product.save(_server, contentType: .multipartForm).then((result) {
      if (result) {
        setState(() {
          product.images;
        });
        flash.show(Text('Sukses Simpan'), .success);
        _tabManager.changeTabHeader(widget, 'Edit Produk ${product.id}');
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
        setState(() {
          product.id = null;
          product.barcode = '';
          for (final tagging in product.taggings) {
            tagging.id = null;
          }
          product.images.clear();
          controller.clearImages();
        });

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
                              child: AsyncDropdown<UnitOfMeasurement>(
                                selected: product.baseUom,
                                onChanged: (value) => product.baseUom = value,

                                label: Text(
                                  "${_setting.columnName('product', 'base_uom')}*",
                                  style: DefaultResponse.labelStyle,
                                ),
                                modelClass: UnitOfMeasurementClass(),
                                isDense: true,
                                validator: (value) {
                                  if (value == null) {
                                    return 'harus diisi';
                                  }
                                  return null;
                                },
                                textOnSearch: (model) => model.name ?? '',
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
                            if (_setting.canShow('product', 'sell_price'))
                              SizedBox(
                                width: 250,
                                child: MoneyFormField(
                                  label: Text(
                                    'Harga Jual',
                                    style: DefaultResponse.labelStyle,
                                  ),
                                  onChanged: (value) => product.sellPrice =
                                      value ?? const Money(0),
                                  initialValue: product.sellPrice,
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
                              isExpanded: panelPool[0] == true,
                              headerBuilder: (context, isExpanded) => Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                  'Detail Produk',
                                  style: DefaultResponse.labelStyle,
                                ),
                              ),
                              body: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TableForm<ProductTag>(
                                  rows: productTags,
                                  actionColumn: TableFormColumn(
                                    desktopWidth: FixedColumnWidth(130),
                                    rowBuilder: (context, productTag) => Align(
                                      alignment: .topRight,
                                      child: IconButton(
                                        onPressed: () => setState(() {
                                          productTags.remove(productTag);
                                        }),
                                        icon: Icon(Icons.delete),
                                      ),
                                    ),
                                    headerBuilder: (context) => Row(
                                      mainAxisAlignment: .spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => setState(() {
                                            productTags.insert(0, ProductTag());
                                          }),
                                          icon: Icon(Icons.add),
                                        ),
                                        IconButton(
                                          onPressed: () => showConfirmDialog(
                                            message:
                                                'Apakah yakin hapus semua?',
                                            onSubmit: () => setState(() {
                                              productTags.clear();
                                            }),
                                          ),
                                          icon: Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                                      key: 'tag_key',
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
                                  ],
                                ),
                              ),
                            ),
                            ExpansionPanel(
                              isExpanded: panelPool[1] == true,
                              canTapOnHeader: true,
                              headerBuilder: (context, isExpanded) => Padding(
                                padding: const .all(10),
                                child: Text(
                                  'Produk Satuan',
                                  style: DefaultResponse.labelStyle,
                                ),
                              ),
                              body: TableForm<ProductMeasurement>(
                                columns: [
                                  TableFormColumn(
                                    title: 'Satuan',
                                    headerBuilder: (context) => Text(
                                      'Satuan',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                    rowBuilder: (context, productMeasurement) =>
                                        AsyncDropdown<UnitOfMeasurement>(
                                          selected: productMeasurement.uom,
                                          textOnSearch: (uom) => uom.name ?? '',
                                          modelClass: UnitOfMeasurementClass(),
                                          onChanged: (model) =>
                                              productMeasurement.uom = model,
                                        ),
                                  ),
                                  TableFormColumn(
                                    title: 'Konversi',
                                    isNumeric: true,
                                    headerBuilder: (context) => Text(
                                      'Konversi',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                    rowBuilder: (context, productMeasurement) =>
                                        NumberFormField<double>(
                                          initialValue:
                                              productMeasurement.conversion,
                                          validator: (value) {
                                            if (value == null) {
                                              return 'harus diisi';
                                            }
                                            if (value < 0) {
                                              return 'tidak boleh negatif';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) =>
                                              productMeasurement.conversion =
                                                  value ?? 0,
                                        ),
                                  ),
                                ],
                                actionColumn: TableFormColumn(
                                  desktopWidth: FixedColumnWidth(130),
                                  headerBuilder: (context) => Row(
                                    mainAxisAlignment: .spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () => setState(() {
                                          product.productMeasurements.add(
                                            ProductMeasurementClass()
                                                .initModel(),
                                          );
                                        }),
                                        icon: Icon(Icons.add),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          if (await showConfirmDialog2(
                                            message:
                                                'Yakin Mau Hapus Semua Satuan Produk',
                                          )) {
                                            setState(() {
                                              product.productMeasurements
                                                  .removeAll();
                                            });
                                          }
                                        },
                                        icon: Icon(Icons.delete),
                                      ),
                                    ],
                                  ),
                                  rowBuilder: (context, productMeasurement) =>
                                      Align(
                                        alignment: .topRight,
                                        child: IconButton(
                                          onPressed: () => setState(() {
                                            product.productMeasurements.remove(
                                              productMeasurement,
                                            );
                                          }),
                                          icon: Icon(Icons.delete),
                                        ),
                                      ),
                                ),
                                rows: product.productMeasurements,
                              ),
                            ),
                            if (_setting.isAuthorize(
                              'stock_keeping_units',
                              'read',
                            ))
                              ExpansionPanel(
                                isExpanded: panelPool[2] == true,
                                canTapOnHeader: true,
                                headerBuilder: (context, isExpanded) => Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'SKU / Varian',
                                    style: DefaultResponse.labelStyle,
                                  ),
                                ),
                                body: TableForm<StockKeepingUnit>(
                                  columns: [
                                    TableFormColumn(
                                      title: 'Barcode',
                                      headerBuilder: (context) => Text(
                                        'Barcode',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          SelectableText(
                                            stockKeepingUnit.barcode,
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Kode Unik',
                                      headerBuilder: (context) => Text(
                                        'Kode Unik',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          SelectableText(
                                            stockKeepingUnit.uniqCode,
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Jumlah',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Jumlah',
                                        style: DefaultResponse.labelStyle,
                                        textAlign: .right,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          SelectableText(
                                            stockKeepingUnit.quantity
                                                    ?.format() ??
                                                '',
                                            textAlign: .right,
                                          ),
                                    ),
                                    if (_setting.canShow(
                                      'stockKeepingUnit',
                                      'cogs',
                                    ))
                                      TableFormColumn(
                                        title: 'Avg HPP',
                                        isNumeric: true,
                                        headerBuilder: (context) => Text(
                                          'Avg HPP',
                                          style: DefaultResponse.labelStyle,
                                          textAlign: .right,
                                        ),
                                        rowBuilder:
                                            (context, stockKeepingUnit) =>
                                                SelectableText(
                                                  stockKeepingUnit.cogs
                                                          ?.format() ??
                                                      '',
                                                  textAlign: .right,
                                                ),
                                      ),
                                    if (_setting.canShow(
                                      'stockKeepingUnit',
                                      'sell_price',
                                    ))
                                      TableFormColumn(
                                        title: 'Harga Jual',
                                        isNumeric: true,
                                        headerBuilder: (context) => Text(
                                          'Harga Jual',
                                          style: DefaultResponse.labelStyle,
                                          textAlign: .right,
                                        ),
                                        rowBuilder:
                                            (
                                              context,
                                              stockKeepingUnit,
                                            ) => Column(
                                              spacing: 10,
                                              children: [
                                                Text(
                                                  stockKeepingUnit
                                                      .stockSellPrices
                                                      .map<String>(
                                                        (
                                                          stockSellPrice,
                                                        ) => stockSellPrice
                                                            .priceWithUomText,
                                                      )
                                                      .join('\n'),
                                                  overflow: .ellipsis,
                                                  textAlign: .right,
                                                  maxLines: 2,
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () =>
                                                      showStockSellPriceDialog(
                                                        stockKeepingUnit,
                                                      ),
                                                  icon: Icon(Icons.edit),
                                                  label: Text('ubah'),
                                                ),
                                              ],
                                            ),
                                      ),
                                    TableFormColumn(
                                      title: 'Supplier',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Supplier',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          TextButton(
                                            onPressed:
                                                stockKeepingUnit.supplier ==
                                                    null
                                                ? null
                                                : () {},
                                            child: Text(
                                              stockKeepingUnit.supplier?.name ??
                                                  '',
                                            ),
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Tanggal Expired',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Tanggal Expired',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          Text(
                                            stockKeepingUnit.expiredDate
                                                    ?.format() ??
                                                '',
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Tanggal Produksi',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Tanggal Produksi',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          Text(
                                            stockKeepingUnit.prodDate
                                                    ?.format() ??
                                                '',
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Tanggal Beli',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Tanggal Beli',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          Text(
                                            stockKeepingUnit.purchaseDate
                                                    ?.format() ??
                                                '',
                                          ),
                                    ),
                                    TableFormColumn(
                                      title: 'Kode Produksi',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Kode Produksi',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                      rowBuilder: (context, stockKeepingUnit) =>
                                          Text(stockKeepingUnit.batchCode),
                                    ),
                                  ],
                                  rows: product.stockKeepingUnits,
                                  actionColumn: TableFormColumn(
                                    desktopWidth: FixedColumnWidth(60),
                                    headerBuilder: (context) => IconButton(
                                      onPressed: refreshSku,
                                      icon: Icon(Icons.refresh),
                                    ),
                                    rowBuilder: (context, model) =>
                                        const SizedBox(),
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
                    Visibility(
                      visible: !product.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _resetRecord,
                        child: Text('Reset'),
                      ),
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

  void showStockSellPriceDialog(StockKeepingUnit stockKeepingUnit) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return StockSellPriceFormDialog(
          tabManager: _tabManager,
          navigator: navigator,
          productMeasurements: product.productMeasurements,
          stockKeepingUnit: stockKeepingUnit,
        );
      },
    );
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
