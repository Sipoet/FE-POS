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

  ItemSalesPeriodReport({
    required super.id,
    required this.itemCode,
    required this.itemName,
    required this.itemTypeName,
    required this.supplierCode,
    required this.brandName,
    required this.discountPercentage,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.subtotal,
    required this.discountTotal,
    required this.salesTotal,
  });

  @override
  factory ItemSalesPeriodReport.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return ItemSalesPeriodReport(
      id: json['id'],
      itemCode: attributes['item_code'],
      itemName: attributes['item_name'],
      itemTypeName: attributes['item_type_name'],
      supplierCode: attributes['supplier_code'],
      brandName: attributes['brand_name'],
      discountPercentage: Percentage(attributes['discount_percentage']),
      buyPrice: Money(attributes['buy_price']),
      sellPrice: Money(attributes['sell_price']),
      quantity: attributes['quantity'],
      subtotal: Money(attributes['subtotal']),
      discountTotal: Money(attributes['discount_total']),
      salesTotal: Money(attributes['sales_total']),
    );
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
      };
}
