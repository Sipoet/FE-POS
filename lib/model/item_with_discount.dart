import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/stock_location.dart';
export 'package:fe_pos/model/stock_location.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ItemWithDiscount extends Model {
  String code;
  String name;
  Money sellPriceAfterDiscount;
  Money sellPrice;
  double stockLeft;
  String? discountDesc;
  List<StockLocation> stockLocations = [];

  String uom;
  ItemWithDiscount({
    this.code = '',
    this.name = '',
    this.discountDesc,
    this.uom = '',
    this.stockLeft = 0,
    List<StockLocation>? stockLocations,

    Money? sellPrice,
    Money? sellPriceAfterDiscount,
    super.id,
  }) : sellPriceAfterDiscount = sellPriceAfterDiscount ?? const Money(0),
       sellPrice = sellPrice ?? const Money(0),
       stockLocations = stockLocations ?? [];

  @override
  String get modelName => 'item';

  @override
  Map<String, dynamic> toMap() => {
    'item_code': code,
    'item_name': name,
    'stock_left': stockLeft,
    'stock_locations': stockLocations,
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
    stockLocations = StockLocationClass().findRelationsData(
      relation: json['relationships']?['stocks'],
      included: included,
    );

    sellPriceAfterDiscount =
        Money.tryParse(attributes['sell_price_after_discount']) ??
        sellPriceAfterDiscount;
    uom = attributes['uom'] ?? '';
    stockLeft = double.tryParse(attributes['stock_left'] ?? '') ?? 0;
    sellPrice = Money.tryParse(attributes['sell_price']) ?? sellPrice;
  }

  @override
  String get modelValue => "$code - $name";
}

class ItemWithDiscountClass extends ModelClass<ItemWithDiscount> {
  @override
  ItemWithDiscount initModel() => ItemWithDiscount();
}
