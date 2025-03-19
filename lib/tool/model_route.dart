import 'package:fe_pos/page/menu_page.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/item_type.dart';

import 'package:flutter/material.dart';

class ModelRoute {
  const ModelRoute();

  Type classOf(String text) {
    switch (text) {
      case 'supplier':
        return Supplier;
      case 'item':
        return Item;
      case 'brand':
        return Brand;
      case 'item_type':
        return ItemType;
      default:
        throw 'model not found';
    }
  }

  Widget tablePageOf(String model) {
    Type klass = classOf(model);
    switch (klass) {
      case Supplier:
        return SupplierPage();
      case Item:
        return ItemPage();
      case Brand:
        return BrandPage();
      case ItemType:
        return ItemTypePage();
      default:
        throw 'model not registered';
    }
  }

  Widget detailPageOf(Model model) {
    switch (model.runtimeType) {
      case Supplier:
        return SupplierFormPage(supplier: model as Supplier);
      case Item:
        return ItemFormPage(item: model as Item);
      case Brand:
        return BrandFormPage(
          brand: model as Brand,
        );
      case ItemType:
        return ItemTypeFormPage(itemType: model as ItemType);
      default:
        throw 'model not registered';
    }
  }
}
