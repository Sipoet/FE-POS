import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';

class ItemReport extends Model {
  String itemCode;
  String itemName;
  String itemTypeName;
  String itemTypeDesc;
  String supplierCode;
  String supplierName;
  String? brandName;
  Percentage percentageSales;
  Money sellPrice;
  Money avgBuyPrice;
  int numberOfSales;
  int storeStock;
  int warehouseStock;
  double stockLeft;
  Money salesTotal;
  int numberOfPurchase;
  Money purchaseTotal;
  Money grossProfit;
  int itemOut;
  bool isConsignment;
  DateTime? recentPurchaseDate;
  Item? item;
  Supplier? supplier;
  Brand? brand;
  ItemType? itemType;
  Money cogs;
  Money lastBuyPrice;
  Percentage margin;
  int numberOfReturn;

  ItemReport(
      {super.id,
      this.itemCode = '',
      this.itemName = '',
      this.itemTypeName = '',
      this.itemTypeDesc = '',
      this.supplierCode = '',
      this.supplierName = '',
      this.brandName,
      this.itemType,
      this.supplier,
      this.item,
      this.brand,
      this.storeStock = 0,
      this.warehouseStock = 0,
      this.percentageSales = const Percentage(0),
      this.sellPrice = const Money(0),
      this.avgBuyPrice = const Money(0),
      this.numberOfSales = 0,
      this.salesTotal = const Money(0),
      this.numberOfPurchase = 0,
      this.purchaseTotal = const Money(0),
      this.margin = const Percentage(0),
      this.itemOut = 0,
      this.cogs = const Money(0),
      this.lastBuyPrice = const Money(0),
      this.numberOfReturn = 0,
      this.stockLeft = 0,
      this.grossProfit = const Money(0),
      this.isConsignment = false,
      this.recentPurchaseDate});
  @override
  factory ItemReport.fromJson(Map<String, dynamic> json,
      {List included = const [], ItemReport? model}) {
    model ??= ItemReport();
    var attributes = json['attributes'];
    model.id = json['id'];
    model.itemCode = attributes['item_code'];
    model.itemName = attributes['item_name'];
    model.itemTypeName = attributes['item_type_name'];
    model.itemTypeDesc = attributes['item_type_desc'];
    model.supplierCode = attributes['supplier_code'];
    model.supplierName = attributes['supplier_name'];
    model.storeStock = attributes['store_stock'];
    model.warehouseStock = attributes['warehouse_stock'];
    model.brandName = attributes['brand_name'] ?? '';
    model.isConsignment = attributes['is_consignment'];
    model.stockLeft = double.tryParse(attributes['stock_left'].toString()) ?? 0;
    model.percentageSales = Percentage(attributes['percentage_sales']);
    model.margin = Percentage(attributes['margin'] ?? -1);
    model.cogs = Money.parse(attributes['cogs'] ?? '0');
    model.numberOfReturn = attributes['qty_return'];
    model.sellPrice =
        Money.tryParse(attributes['sell_price']) ?? const Money(0);
    model.avgBuyPrice =
        Money.tryParse(attributes['avg_buy_price']) ?? const Money(0);
    model.numberOfSales = attributes['number_of_sales'];
    model.salesTotal =
        Money.tryParse(attributes['sales_total']) ?? const Money(0);
    model.numberOfPurchase = attributes['number_of_purchase'];
    model.itemOut = attributes['item_out'];
    model.purchaseTotal =
        Money.tryParse(attributes['purchase_total']) ?? const Money(0);
    model.grossProfit =
        Money.tryParse(attributes['gross_profit']) ?? const Money(0);
    model.recentPurchaseDate =
        DateTime.tryParse(attributes['recent_purchase_date'] ?? '');
    model.item = Model.findRelationData<Item>(
        relation: json['relationships']?['item'],
        included: included,
        convert: Item.fromJson);
    model.itemType = Model.findRelationData<ItemType>(
        relation: json['relationships']?['item_type'],
        included: included,
        convert: ItemType.fromJson);
    model.brand = Model.findRelationData<Brand>(
        relation: json['relationships']?['brand'],
        included: included,
        convert: Brand.fromJson);
    model.supplier = Model.findRelationData<Supplier>(
        relation: json['relationships']?['supplier'],
        included: included,
        convert: Supplier.fromJson);
    return model;
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
        'margin': margin,
        'is_consignment': isConsignment,
        'warehouse_stock': warehouseStock,
        'brand': brandName,
        'brand_name': brandName,
        'percentage_sales': percentageSales,
        'sell_price': sellPrice,
        'avg_buy_price': avgBuyPrice,
        'last_buy_price': lastBuyPrice,
        'number_of_sales': numberOfSales,
        'sales_total': salesTotal,
        'number_of_purchase': numberOfPurchase,
        'purchase_total': purchaseTotal,
        'recent_purchase_date': recentPurchaseDate,
        'item_out': itemOut,
        'gross_profit': grossProfit,
        'stock_left': stockLeft,
        'cogs': cogs,
        'qty_return': numberOfReturn
      };
}
