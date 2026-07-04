import 'package:collection/collection.dart';
import 'package:fe_pos/model/product_measurement.dart';
import 'package:fe_pos/model/item_variant.dart';
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
import 'package:fe_pos/widget/authorizer_form_field.dart';
import 'package:fe_pos/widget/product_sell_price_form_dialog.dart';
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
  late final Authorizer _setting;
  late final Server _server;
  late final TabManager _tabManager;
  late final ImageCarouselController controller;
  final ValueNotifier<bool> modelToggleNotifier = ValueNotifier(false);
  final _formState = GlobalKey<FormState>();
  final flash = Flash();
  bool _showForm = true;
  List<ProductTag> productTags = [];
  Map<int, bool> panelPool = {};

  @override
  void initState() {
    _setting = context.read<Authorizer>();
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
          refreshItemVariant();
        })
        .whenComplete(() {
          setState(() {
            _showForm = true;
          });
          hideLoadingPopup();
        });
  }

  void refreshItemVariant() {
    if (!_setting.isAuthorize('item_variants', 'read')) {
      return;
    }
    final queryRequest = QueryRequest(
      include: ['image', 'product_sell_prices', 'tags', 'taggings'],
    );
    ItemVariantClass().finds(_server, queryRequest, parentId: product.id).then(
      ((result) {
        setState(() {
          product.itemVariants = result.models;
        });
      }),
    );
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();

    product.setTags(productTags.map((e) => e.tag!).toList());

    product.save(_server, contentType: .multipartForm).then((isSuccess) {
      if (isSuccess) {
        modelToggleNotifier.toggle();
        final variantSaveProcess = product.itemVariants.map((itemVariant) {
          itemVariant.parentId = product.id;
          if (itemVariant.isDestroyed) {
            return itemVariant.destroy(_server);
          } else {
            return itemVariant.save(_server, contentType: .multipartForm);
          }
        }).toList();
        Future.wait(variantSaveProcess).then((result) {
          if (!result.contains(false)) {
            setState(() {
              product.images;
            });
            flash.show(Text('Sukses Simpan'), .success);
            _tabManager.changeTabHeader(widget, 'Edit Produk ${product.id}');
            refreshItemVariant();
          }
        });
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
    final defaultSetting = context.read<DefaultSetting>();
    Future.delayed(Durations.short1, () {
      setState(() {
        product = ProductClass().initModel();
        product.baseUom = defaultSetting.uom;
        product.stockAccount = defaultSetting.stockAccount;
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
                      mainAxisSize: .min,
                      children: [
                        Wrap(
                          alignment: .start,
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
                            MultipleImageFormField(
                              width: 200,
                              height: 200,
                              validator: (List<ImageModel>? images) {
                                if (images != null && images.length > 5) {
                                  return 'maksimal 5 gambar';
                                }
                                for (final ImageModel image in images ?? []) {
                                  if (image.fileSize != null &&
                                      image.fileSize! > 500_000) {
                                    return 'maksimal per gambar 500 KB';
                                  }
                                }
                                return null;
                              },
                              onChanged: (images) {
                                setState(() {
                                  controller.addImages(images);
                                  product.images.addAll(images);
                                });
                              },
                            ),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                initialValue: product.supplierProductCode,
                                onChanged: (value) =>
                                    product.supplierProductCode = value,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
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
                                readOnly: !product.isNewRecord,
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
                                allowClear: false,
                                textOnSearch: (model) => model.name ?? '',
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: AsyncDropdown<ProductCategory>(
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
                                isShowItemDescription: true,
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
                              child: AuthorizerFormField(
                                columnName: 'barcode',
                                tableName: 'product',
                                notifier: modelToggleNotifier,
                                valueCallback: () => product.barcode,
                                childBuilder: (controller) => TextFormField(
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) => product.barcode = value,
                                  controller: controller,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .singleLineFormatter,
                                    UpperCaseTextFormatter(),
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[0-9A-Z]'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
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
                                width: 300,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: MoneyFormField(
                                        label: Text(
                                          'Harga Jual',
                                          style: DefaultResponse.labelStyle,
                                        ),
                                        onChanged: (value) =>
                                            product.sellPrice =
                                                value ?? const Money(0),
                                        initialValue: product.sellPrice,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          showProductSellPriceDialog(product),
                                      icon: Icon(Icons.list_alt_sharp),
                                    ),
                                  ],
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
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
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
                                padding: const EdgeInsets.only(
                                  left: 10.0,
                                  top: 15,
                                ),
                                child: Text(
                                  'Detail/Tag Produk',
                                  style: DefaultResponse.labelStyle,
                                ),
                              ),
                              body: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TableForm<ProductTag>(
                                  rows: productTags,
                                  actionColumn: TableFormColumn(
                                    desktopWidth: FixedColumnWidth(130),
                                    rowBuilder: (context, productTag, index) =>
                                        Align(
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
                                      rowBuilder: (context, productTag, index) {
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
                                      rowBuilder:
                                          (
                                            context,
                                            productTag,
                                            index,
                                          ) => Visibility(
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
                                                          value: productTag
                                                              .tagKeyId,
                                                        ),
                                                      );
                                                      return TagClass().finds(
                                                        _server,
                                                        queryRequest,
                                                      );
                                                    },
                                                    isDense: true,
                                                    onChanged: (tag) => setState(
                                                      () {
                                                        productTag.tag = tag;
                                                        if (tag != null &&
                                                            productTag
                                                                    .tagKeyId !=
                                                                tag.tagKeyId) {
                                                          productTag.tagKey =
                                                              tag.tagKey;
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      productTag.tagKey != null,
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        setState(() {
                                                          productTag.isNewTag =
                                                              !productTag
                                                                  .isNewTag;
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
                                                        RegExp(
                                                          r'[A-Za-z0-9\s]',
                                                        ),
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
                                                      floatingLabelBehavior:
                                                          FloatingLabelBehavior
                                                              .always,
                                                      border:
                                                          OutlineInputBorder(),
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
                                padding: const EdgeInsets.only(
                                  left: 10.0,
                                  top: 15,
                                ),
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
                                    rowBuilder:
                                        (
                                          context,
                                          productMeasurement,
                                          index,
                                        ) => AsyncDropdown<UnitOfMeasurement>(
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
                                    rowBuilder:
                                        (
                                          context,
                                          productMeasurement,
                                          index,
                                        ) => NumberFormField<double>(
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
                                  rowBuilder:
                                      (context, productMeasurement, index) =>
                                          Align(
                                            alignment: .topRight,
                                            child: IconButton(
                                              onPressed: () => setState(() {
                                                product.productMeasurements
                                                    .remove(productMeasurement);
                                              }),
                                              icon: Icon(Icons.delete),
                                            ),
                                          ),
                                ),
                                rows: product.productMeasurements,
                              ),
                            ),
                            ExpansionPanel(
                              isExpanded: panelPool[2] == true,
                              canTapOnHeader: true,
                              headerBuilder: (context, isExpanded) => Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Variasi',
                                        style: DefaultResponse.labelStyle,
                                      ),
                                    ),
                                    if (!product.isNewRecord)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15,
                                        ),
                                        child: IconButton(
                                          onPressed: refreshItemVariant,
                                          icon: Icon(Icons.refresh),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              body: TableForm<ItemVariant>(
                                columns: [
                                  TableFormColumn(
                                    title: 'Tag',
                                    headerBuilder: (context) => Text(
                                      'Tag',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                    rowBuilder: (context, itemVariant, index) =>
                                        AsyncDropdownMultiple<Tag>(
                                          selecteds: itemVariant.tags,
                                          validator: (models) {
                                            if (models == null ||
                                                models.isEmpty) {
                                              return 'harus diisi';
                                            }
                                            return null;
                                          },
                                          textOnSearch: (model) =>
                                              '${model.tagKey?.name}: ${model.value}',
                                          textOnSelected: (model) =>
                                              model.value,
                                          modelClass: TagClass(),
                                          onChanged: (models) =>
                                              itemVariant.setTags(models),
                                        ),
                                  ),
                                  TableFormColumn(
                                    title: 'Barcode',
                                    headerBuilder: (context) => Text(
                                      'Barcode',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                    rowBuilder: (context, itemVariant, index) =>
                                        TextFormField(
                                          keyboardType: TextInputType.text,
                                          onChanged: (value) =>
                                              itemVariant.barcode = value,
                                          initialValue: itemVariant.barcode,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .singleLineFormatter,
                                            UpperCaseTextFormatter(),
                                            FilteringTextInputFormatter.allow(
                                              RegExp('[0-9A-Z]'),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.always,
                                            hintText: 'Auto',
                                            helperText:
                                                'hanya boleh diisi huruf dan angka',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                  ),
                                  if (_setting.canShow('product', 'sell_price'))
                                    TableFormColumn(
                                      title: 'Harga Jual',
                                      isNumeric: true,
                                      headerBuilder: (context) => Text(
                                        'Harga Jual',
                                        style: DefaultResponse.labelStyle,
                                        textAlign: .right,
                                      ),

                                      rowBuilder:
                                          (context, itemVariant, index) => Row(
                                            children: [
                                              Flexible(
                                                child: MoneyFormField(
                                                  onChanged: (value) =>
                                                      itemVariant.sellPrice =
                                                          value ??
                                                          const Money(0),
                                                  initialValue:
                                                      itemVariant.sellPrice,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    showProductSellPriceDialog(
                                                      itemVariant,
                                                    ),
                                                icon: Icon(
                                                  Icons.list_alt_sharp,
                                                ),
                                              ),
                                            ],
                                          ),
                                    ),

                                  TableFormColumn(
                                    title: 'Gambar',
                                    isNumeric: true,
                                    desktopWidth: const FixedColumnWidth(150),
                                    headerBuilder: (context) => Text(
                                      'Gambar',
                                      style: DefaultResponse.labelStyle,
                                    ),
                                    rowBuilder: (context, itemVariant, index) =>
                                        ImageFormField(
                                          width: 100,
                                          height: 100,
                                          initialValue: itemVariant.image,
                                          validator: (ImageModel? image) {
                                            if (image == null) {
                                              return null;
                                            }
                                            if (image.fileSize != null &&
                                                image.fileSize! > 500_000) {
                                              return 'maksimal per gambar 500 KB';
                                            }
                                            return null;
                                          },
                                          onChanged: (image) {
                                            setState(() {
                                              itemVariant.image = image;
                                            });
                                          },
                                        ),
                                  ),
                                ],
                                rows: product.itemVariants
                                    .whereNot((e) => e.isDestroyed)
                                    .toList(),
                                actionColumn: TableFormColumn(
                                  desktopWidth: FixedColumnWidth(200),
                                  headerBuilder: (context) => Row(
                                    mainAxisAlignment: .spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed: _addVariant,
                                        icon: Icon(Icons.add),
                                      ),
                                      IconButton(
                                        onPressed: _showgenerateVariantDialog,
                                        icon: Icon(Icons.copy),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          if (await showConfirmDialog2(
                                            message:
                                                'Apakah yakin hapus semua varian?',
                                          )) {
                                            setState(() {
                                              product.itemVariants.removeAll();
                                              product.itemVariants;
                                            });
                                          }
                                        },
                                        icon: Icon(Icons.delete),
                                      ),
                                    ],
                                  ),
                                  rowBuilder: (context, itemVariant, index) =>
                                      Row(
                                        mainAxisAlignment: .spaceEvenly,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                final int index =
                                                    product.itemVariants
                                                        .indexOf(itemVariant) +
                                                    1;
                                                product.itemVariants.insert(
                                                  index,
                                                  ItemVariant(
                                                    description:
                                                        itemVariant.description,
                                                    barcode:
                                                        itemVariant.barcode,
                                                    taggings:
                                                        itemVariant.taggings,
                                                    image: itemVariant.image,
                                                    sellPrice:
                                                        itemVariant.sellPrice,
                                                  ),
                                                );
                                              });
                                            },
                                            icon: Icon(Icons.copy),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (itemVariant.isNewRecord) {
                                                  product.itemVariants.remove(
                                                    itemVariant,
                                                  );
                                                } else {
                                                  itemVariant.flagDestroy();
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.delete),
                                          ),
                                        ],
                                      ),
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

  void _addVariant() {
    setState(() {
      product.itemVariants.add(ItemVariant(sellPrice: product.sellPrice));
    });
  }

  void _showgenerateVariantDialog() {
    Map<int, List<Tag>> data = {};
    List<TagKey> tagKeys = [TagKey()];
    final formState = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        final size = MediaQuery.sizeOf(context);
        return StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: formState,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: AlertDialog(
                  title: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Flexible(child: Text('Varian Generator')),
                      IconButton(
                        onPressed: () => navigator.pop(),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    height: size.height,
                    width: size.width,
                    child: TableForm<TagKey>(
                      columns: [
                        TableFormColumn(
                          headerBuilder: (context) => Text('Kategori'),
                          title: 'Kategori',
                          rowBuilder: (context, model, index) =>
                              AsyncDropdown<TagKey>(
                                textOnSearch: (tagKey) => tagKey.name,
                                modelClass: TagKeyClass(),
                                onChanged: (tagKey) => setStateDialog(() {
                                  model.id = tagKey?.id;
                                  model.name = tagKey?.name ?? model.name;
                                  model.group = tagKey?.group;
                                }),
                              ),
                        ),
                        TableFormColumn(
                          headerBuilder: (context) => Text('Opsi'),
                          title: 'Opsi',
                          rowBuilder: (context, model, index) =>
                              AsyncDropdownMultiple<Tag>(
                                textOnSearch: (model) => model.value,
                                modelClass: TagClass(),
                                request: (queryRequest) {
                                  queryRequest.filters = [
                                    ComparisonFilterData(
                                      key: 'tag_key',
                                      value: model.id,
                                    ),
                                  ];
                                  return TagClass().finds(
                                    _server,
                                    queryRequest,
                                  );
                                },
                                onChanged: (models) =>
                                    data[tagKeys.indexOf(model)] = models,
                              ),
                        ),
                      ],
                      rows: tagKeys,
                      actionColumn: TableFormColumn(
                        rowBuilder: (context, model, index) => IconButton(
                          onPressed: () => setStateDialog(() {
                            final index = tagKeys.indexOf(model);
                            tagKeys.removeAt(index);
                            data.remove(index);
                          }),
                          icon: Icon(Icons.delete),
                        ),
                        headerBuilder: (context) => IconButton(
                          onPressed: () => setStateDialog(() {
                            tagKeys.add(TagKey());
                          }),
                          icon: Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        if (formState.currentState?.validate() == true) {
                          setState(() {
                            _generateVariant(
                              root: data.values.toList(),
                              index: 0,
                              values: [],
                            );
                          });
                          navigator.pop();
                        }
                      },
                      child: Text('Generate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _generateVariant({
    required int index,
    required List<List<Tag>> root,
    required List<Tag> values,
  }) {
    if (root.length <= index) {
      final itemVariant = ItemVariant(
        description: product.description,
        sellPrice: product.sellPrice,
      );
      itemVariant.setTags(values);
      product.itemVariants.add(itemVariant);
      return;
    }
    for (final tag in root[index]) {
      final newValues = values.toList();
      newValues.add(tag);
      _generateVariant(index: index + 1, root: root, values: newValues);
    }
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

  void showProductSellPriceDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return ProductSellPriceFormDialog(
          tabManager: _tabManager,
          navigator: navigator,
          productMeasurements: product.productMeasurements,
          product: product,
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
