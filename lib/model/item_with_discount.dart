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
  factory ItemWithDiscount.fromJson(Map<String, dynamic> json,
      {ItemWithDiscount? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= ItemWithDiscount();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.code = attributes['item_code'];
    model.name = attributes['item_name'];
    model.discountDesc = attributes['discount_desc'];
    model.storeStock = double.parse(attributes['store_stock']);
    model.warehouseStock = double.parse(attributes['warehouse_stock']);
    model.sellPriceAfterDiscount =
        Money.tryParse(attributes['sell_price_after_discount']) ??
            model.sellPriceAfterDiscount;
    model.uom = attributes['uom'] ?? '';
    model.sellPrice =
        Money.tryParse(attributes['sell_price']) ?? model.sellPrice;
    return model;
  }

  @override
  String get modelValue => "$code - $name";
}
