import 'package:fe_pos/page/menu_page.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/model/all_model.dart';
import 'package:flutter/material.dart';

class ModelRoute {
  const ModelRoute();

  static const Map<String, Widget> _tablePages = {
    'supplier': SupplierPage(),
    'item': ItemPage(),
    'brand': BrandPage(),
    'item_type': ItemTypePage(),
  };

  static const Map<String, Type> _modelList = {
    'supplier': Supplier,
    'item': Item,
    'brand': Brand,
    'item_type': ItemType,
  };

  Type classOf(String className) {
    return _modelList[className]!;
  }

  Widget tablePageOf(String className) {
    return _tablePages[className]!;
  }

  Widget detailPageOf(Model model) {
    switch (model.runtimeType) {
      case const (Supplier):
        return SupplierFormPage(supplier: model as Supplier);
      case const (Item):
        return ItemFormPage(item: model as Item);
      case const (Brand):
        return BrandFormPage(brand: model as Brand);
      case const (ItemType):
        return ItemTypeFormPage(itemType: model as ItemType);
      default:
        throw 'model not registered';
    }
  }
}
