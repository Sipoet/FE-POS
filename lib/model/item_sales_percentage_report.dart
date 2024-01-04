import 'package:fe_pos/model/model.dart';

class ItemSalesPercentageReport extends Model {
  String id;
  String itemCode;
  String itemName;
  String itemType;
  String supplier;
  String brand;
  String percentageSales;
  double sellPrice;
  double avgBuyPrice;
  int numberOfSales;
  double salesTotal;
  int numberOfPurchase;
  double purchaseTotal;

  ItemSalesPercentageReport({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemType,
    required this.supplier,
    required this.brand,
    required this.percentageSales,
    required this.sellPrice,
    required this.avgBuyPrice,
    required this.numberOfSales,
    required this.salesTotal,
    required this.numberOfPurchase,
    required this.purchaseTotal,
  });
  @override
  factory ItemSalesPercentageReport.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return ItemSalesPercentageReport(
        id: json['id'],
        itemCode: attributes['item_code'],
        itemName: attributes['item_name'],
        itemType: attributes['item_type'],
        supplier: attributes['supplier'],
        brand: attributes['brand'],
        percentageSales: attributes['percentage_sales'],
        sellPrice: attributes['sell_price'],
        avgBuyPrice: attributes['avg_buy_price'],
        numberOfSales: attributes['number_of_sales'],
        salesTotal: attributes['sales_total'],
        numberOfPurchase: attributes['number_of_purchase'],
        purchaseTotal: attributes['purchase_total']);
  }

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item_name': itemName,
        'item_type': itemType,
        'supplier': supplier,
        'brand': brand,
        'percentage_sales': percentageSales,
        'sell_price': sellPrice,
        'avg_buy_price': avgBuyPrice,
        'number_of_sales': numberOfSales,
        'sales_total': salesTotal,
        'number_of_purchase': numberOfPurchase,
        'purchase_total': purchaseTotal
      };

  @override
  Map<String, dynamic> toJson() {
    return toMap();
  }
}
