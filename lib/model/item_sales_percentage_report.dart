import 'package:fe_pos/model/model.dart';

class ItemSalesPercentageReport extends Model {
  String itemCode;
  String itemName;
  String itemType;
  String itemTypeDesc;
  String supplierCode;
  String supplierName;
  String brand;
  Percentage percentageSales;
  Money sellPrice;
  Money avgBuyPrice;
  int numberOfSales;
  int storeStock;
  int warehouseStock;
  Money salesTotal;
  int numberOfPurchase;
  Money purchaseTotal;
  int itemOut;
  DateTime? recentPurchaseDate;

  ItemSalesPercentageReport(
      {super.id,
      required this.itemCode,
      required this.itemName,
      required this.itemType,
      required this.itemTypeDesc,
      required this.supplierCode,
      required this.supplierName,
      required this.brand,
      required this.storeStock,
      required this.warehouseStock,
      required this.percentageSales,
      required this.sellPrice,
      required this.avgBuyPrice,
      required this.numberOfSales,
      required this.salesTotal,
      required this.numberOfPurchase,
      required this.purchaseTotal,
      required this.itemOut,
      this.recentPurchaseDate});
  @override
  factory ItemSalesPercentageReport.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return ItemSalesPercentageReport(
        id: json['id'],
        itemCode: attributes['item_code'],
        itemName: attributes['item_name'],
        itemType: attributes['item_type'],
        itemTypeDesc: attributes['item_type_desc'],
        supplierCode: attributes['supplier_code'],
        supplierName: attributes['supplier_name'],
        storeStock: attributes['store_stock'],
        warehouseStock: attributes['warehouse_stock'],
        brand: attributes['brand'],
        percentageSales: Percentage(attributes['percentage_sales']),
        sellPrice: Money(attributes['sell_price']),
        avgBuyPrice: Money(attributes['avg_buy_price']),
        numberOfSales: attributes['number_of_sales'],
        salesTotal: Money(attributes['sales_total']),
        numberOfPurchase: attributes['number_of_purchase'],
        itemOut: attributes['item_out'],
        purchaseTotal: Money(attributes['purchase_total']),
        recentPurchaseDate:
            DateTime.tryParse(attributes['recent_purchase_date'] ?? ''));
  }

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item_name': itemName,
        'item_type': itemType,
        'item_type_desc': itemTypeDesc,
        'supplier_code': supplierCode,
        'supplier_name': supplierName,
        'store_stock': storeStock,
        'warehouse_stock': warehouseStock,
        'brand': brand,
        'percentage_sales': percentageSales,
        'sell_price': sellPrice,
        'avg_buy_price': avgBuyPrice,
        'number_of_sales': numberOfSales,
        'sales_total': salesTotal,
        'number_of_purchase': numberOfPurchase,
        'purchase_total': purchaseTotal,
        'recent_purchase_date': recentPurchaseDate,
        'item_out': itemOut,
      };
}
