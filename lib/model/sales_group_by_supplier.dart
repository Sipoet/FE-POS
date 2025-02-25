import 'package:fe_pos/model/model.dart';

class SalesGroupBySupplier extends Model {
  String? itemTypeName;
  String? supplierCode;
  String? supplierName;
  String? brandName;
  Percentage salesPercentage;
  Date? lastPurchaseDate;
  int numberOfPurchase;
  int numberOfSales;
  int stockLeft;
  Money salesTotal;
  Money purchaseTotal;
  Money grossProfit;

  SalesGroupBySupplier({
    required super.id,
    required this.itemTypeName,
    required this.supplierCode,
    required this.supplierName,
    required this.brandName,
    this.lastPurchaseDate,
    required this.salesPercentage,
    required this.numberOfPurchase,
    required this.numberOfSales,
    required this.stockLeft,
    required this.salesTotal,
    required this.purchaseTotal,
    required this.grossProfit,
  });

  String get supplier => "$supplierCode - $supplierName";

  @override
  factory SalesGroupBySupplier.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return SalesGroupBySupplier(
      id: json['id'],
      lastPurchaseDate: Date.tryParse(attributes['last_purchase_date'] ?? ''),
      itemTypeName: attributes['item_type_name'],
      supplierCode: attributes['supplier_code'],
      supplierName: attributes['supplier_name'],
      brandName: attributes['brand_name'],
      salesPercentage: Percentage(attributes['sales_percentage']),
      numberOfPurchase: attributes['number_of_purchase'],
      numberOfSales: attributes['number_of_sales'],
      stockLeft: attributes['stock_left'],
      grossProfit: Money.tryParse(attributes['gross_profit']) ?? const Money(0),
      salesTotal: Money.tryParse(attributes['sales_total']) ?? const Money(0),
      purchaseTotal:
          Money.tryParse(attributes['purchase_total']) ?? const Money(0),
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
        'supplier': supplier,
        'sales_total': salesTotal,
        'purchase_total': purchaseTotal,
        'gross_profit': grossProfit,
        'last_purchase_date': lastPurchaseDate,
      };
}
