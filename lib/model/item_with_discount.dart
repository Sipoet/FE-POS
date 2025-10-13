import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class ItemWithDiscount extends Model {
  String code;
  String name;
  Money sellPriceAfterDiscount;
  Money sellPrice;
  String? discountDesc;
  double warehouseStock;
  double storeStock;
  String uom;
  ItemWithDiscount(
      {this.code = '',
      this.name = '',
      this.discountDesc,
      this.uom = '',
      this.warehouseStock = 0,
      this.storeStock = 0,
      Money? sellPrice,
      Money? sellPriceAfterDiscount,
      super.id})
      : sellPriceAfterDiscount = sellPriceAfterDiscount ?? const Money(0),
        sellPrice = sellPrice ?? const Money(0);

  @override
  String get modelName => 'item';

  @override
  Map<String, dynamic> toMap() => {
        'item_code': code,
        'item_name': name,
        'warehouse_stock': warehouseStock,
        'store_stock': storeStock,
        'discount_desc': discountDesc,
        'sell_price': sellPrice,
        'discount_amount': discountAmount,
        'sell_price_after_discount': sellPriceAfterDiscount,
        'uom': uom,
      };

  Money get discountAmount => sellPrice - sellPriceAfterDiscount;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    code = attributes['item_code'];
    name = attributes['item_name'];
    discountDesc = attributes['discount_desc'];
    storeStock = double.parse(attributes['store_stock']);
    warehouseStock = double.parse(attributes['warehouse_stock']);
    sellPriceAfterDiscount =
        Money.tryParse(attributes['sell_price_after_discount']) ??
            sellPriceAfterDiscount;
    uom = attributes['uom'] ?? '';
    sellPrice = Money.tryParse(attributes['sell_price']) ?? sellPrice;
  }

  @override
  String get modelValue => "$code - $name";
}

class ItemWithDiscountClass extends ModelClass<ItemWithDiscount> {
  @override
  ItemWithDiscount initModel() => ItemWithDiscount();
}
