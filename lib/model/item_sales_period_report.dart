import 'package:fe_pos/model/model.dart';

class ItemSalesPeriodReport extends Model {
  String itemCode;
  String itemName;
  String? itemTypeName;
  String? supplierCode;
  String? brandName;
  Percentage discountPercentage;
  int quantity;
  Money buyPrice;
  Money sellPrice;
  Money subtotal;
  Money discountTotal;
  Money salesTotal;
  bool isConsignment;

  ItemSalesPeriodReport({
    super.id,
    this.itemCode = '',
    this.itemName = '',
    this.itemTypeName,
    this.supplierCode,
    this.brandName,
    this.discountPercentage = const Percentage(0),
    this.buyPrice = const Money(0),
    this.sellPrice = const Money(999999),
    this.quantity = 0,
    this.subtotal = const Money(0),
    this.discountTotal = const Money(0),
    this.salesTotal = const Money(0),
    this.isConsignment = false,
  });

  @override
  String get modelName => 'item_sales_period_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    id = json['id'];
    itemCode = attributes['item_code'];
    itemName = attributes['item_name'];
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];
    discountPercentage = Percentage(attributes['discount_percentage']);
    buyPrice = Money(attributes['buy_price']);
    sellPrice = Money(attributes['sell_price']);
    quantity = attributes['quantity'];
    subtotal = Money(attributes['subtotal']);
    discountTotal = Money(attributes['discount_total']);
    salesTotal = Money(attributes['sales_total']);
    isConsignment = attributes['is_consignment'] == true;
  }

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item_name': itemName,
        'item_type_name': itemTypeName,
        'supplier_code': supplierCode,
        'brand_name': brandName,
        'discount_percentage': discountPercentage,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'discount_total': discountTotal,
        'sales_total': salesTotal,
        'is_consignment': isConsignment,
      };
  @override
  String get modelValue => itemCode;
}

class ItemSalesPeriodReportClass extends ModelClass<ItemSalesPeriodReport> {
  @override
  ItemSalesPeriodReport initModel() => ItemSalesPeriodReport();
}
