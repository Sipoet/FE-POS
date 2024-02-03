import 'package:fe_pos/model/model.dart';

class SalesGroupBySupplier extends Model {
  String id;
  String? itemTypeName;
  String? supplierCode;
  String? supplierName;
  String? brandName;
  Percentage salesPercentage;
  int numberOfPurchase;
  int numberOfSales;
  int stockLeft;

  SalesGroupBySupplier({
    required this.id,
    required this.itemTypeName,
    required this.supplierCode,
    required this.supplierName,
    required this.brandName,
    required this.salesPercentage,
    required this.numberOfPurchase,
    required this.numberOfSales,
    required this.stockLeft,
  });

  @override
  factory SalesGroupBySupplier.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return SalesGroupBySupplier(
      id: json['id'],
      itemTypeName: attributes['item_type_name'],
      supplierCode: attributes['supplier_code'],
      supplierName: attributes['supplier_name'],
      brandName: attributes['brand_name'],
      salesPercentage: Percentage(attributes['sales_percentage']),
      numberOfPurchase: attributes['number_of_purchase'],
      numberOfSales: attributes['number_of_sales'],
      stockLeft: attributes['stock_left'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'item_type_name': itemTypeName,
        'supplier_code': supplierCode,
        'supplier_name': supplierName,
        'brand_name': brandName,
        'sales_percentage': salesPercentage,
        'number_of_purchase': numberOfPurchase,
        'number_of_sales': numberOfSales,
        'stock_left': stockLeft,
      };
}
