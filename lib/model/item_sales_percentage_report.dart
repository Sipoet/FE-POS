import 'package:fe_pos/model/model.dart';

class ItemSalesPercentageReport extends Model {
  String itemCode;
  String itemName;
  String itemTypeName;
  String itemTypeDesc;
  String supplierCode;
  String supplierName;
  String brandName;
  Percentage percentageSales;
  Money sellPrice;
  Money avgBuyPrice;
  int numberOfSales;
  int storeStock;
  int warehouseStock;
  int stockLeft;
  Money salesTotal;
  int numberOfPurchase;
  Money purchaseTotal;
  Money grossProfit;
  int itemOut;
  DateTime? recentPurchaseDate;

  ItemSalesPercentageReport(
      {super.id,
      required this.itemCode,
      required this.itemName,
      required this.itemTypeName,
      required this.itemTypeDesc,
      required this.supplierCode,
      required this.supplierName,
      required this.brandName,
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
      this.stockLeft = 0,
      required this.grossProfit,
      this.recentPurchaseDate});
  @override
  factory ItemSalesPercentageReport.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    var attributes = json['attributes'];
    return ItemSalesPercentageReport(
        id: json['id'],
        itemCode: attributes['item_code'],
        itemName: attributes['item_name'],
        itemTypeName: attributes['item_type_name'],
        itemTypeDesc: attributes['item_type_desc'],
        supplierCode: attributes['supplier_code'],
        supplierName: attributes['supplier_name'],
        storeStock: attributes['store_stock'],
        warehouseStock: attributes['warehouse_stock'],
        brandName: attributes['brand_name'] ?? '',
        stockLeft: int.tryParse(attributes['stock_left']) ?? 0,
        percentageSales: Percentage(attributes['percentage_sales']),
        sellPrice: Money.tryParse(attributes['sell_price']) ?? const Money(0),
        avgBuyPrice:
            Money.tryParse(attributes['avg_buy_price']) ?? const Money(0),
        numberOfSales: attributes['number_of_sales'],
        salesTotal: Money.tryParse(attributes['sales_total']) ?? const Money(0),
        numberOfPurchase: attributes['number_of_purchase'],
        itemOut: attributes['item_out'],
        purchaseTotal:
            Money.tryParse(attributes['purchase_total']) ?? const Money(0),
        grossProfit:
            Money.tryParse(attributes['gross_profit']) ?? const Money(0),
        recentPurchaseDate:
            DateTime.tryParse(attributes['recent_purchase_date'] ?? ''));
  }

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item_name': itemName,
        'item_type_name': itemTypeName,
        'item_type_desc': itemTypeDesc,
        'supplier_code': supplierCode,
        'supplier_name': supplierName,
        'store_stock': storeStock,
        'warehouse_stock': warehouseStock,
        'brand': brandName,
        'brand_name': brandName,
        'percentage_sales': percentageSales,
        'sell_price': sellPrice,
        'avg_buy_price': avgBuyPrice,
        'number_of_sales': numberOfSales,
        'sales_total': salesTotal,
        'number_of_purchase': numberOfPurchase,
        'purchase_total': purchaseTotal,
        'recent_purchase_date': recentPurchaseDate,
        'item_out': itemOut,
        'gross_profit': grossProfit,
        'stock_left': stockLeft,
      };
}
