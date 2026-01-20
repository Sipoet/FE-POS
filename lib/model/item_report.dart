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
  DateTime? lastPurchaseDate;
  Item item;
  Supplier supplier;
  Brand brand;
  ItemType itemType;
  Money cogs;
  Money lastBuyPrice;
  Percentage margin;
  Percentage limitProfitDiscount;
  int numberOfReturn;

  ItemReport({
    super.id,
    this.itemCode = '',
    this.itemName = '',
    this.itemTypeName = '',
    this.itemTypeDesc = '',
    this.supplierCode = '',
    this.supplierName = '',
    this.brandName,
    ItemType? itemType,
    Supplier? supplier,
    Item? item,
    Brand? brand,
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
    this.limitProfitDiscount = const Percentage(0),
    this.itemOut = 0,
    this.cogs = const Money(0),
    this.lastBuyPrice = const Money(0),
    this.numberOfReturn = 0,
    this.stockLeft = 0,
    this.grossProfit = const Money(0),
    this.isConsignment = false,
    this.lastPurchaseDate,
  }) : item = item ?? Item(id: itemCode),
       supplier = supplier ?? Supplier(id: supplierCode),
       itemType = itemType ?? ItemType(id: itemTypeName),
       brand = brand ?? Brand(id: brandName);

  @override
  String get modelName => 'item_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    id = json['id'];
    itemCode = attributes['item_code'];
    itemName = attributes['item_name'];
    itemTypeName = attributes['item_type_name'];
    itemTypeDesc = attributes['item_type_desc'];
    supplierCode = attributes['supplier_code'];
    supplierName = attributes['supplier_name'];
    storeStock = attributes['store_stock'];
    warehouseStock = attributes['warehouse_stock'];
    brandName = attributes['brand_name'] ?? '';
    isConsignment = attributes['is_consignment'];
    stockLeft = double.tryParse(attributes['stock_left'].toString()) ?? 0;
    percentageSales = Percentage(attributes['percentage_sales']);
    margin = Percentage(attributes['margin'] ?? -1);
    limitProfitDiscount = Percentage(attributes['limit_profit_discount'] ?? -1);
    cogs = Money.parse(attributes['cogs'] ?? '0');
    numberOfReturn = attributes['qty_return'];
    sellPrice = Money.tryParse(attributes['sell_price']) ?? const Money(0);
    avgBuyPrice = Money.tryParse(attributes['avg_buy_price']) ?? const Money(0);
    numberOfSales = attributes['number_of_sales'];
    salesTotal = Money.tryParse(attributes['sales_total']) ?? const Money(0);
    numberOfPurchase = attributes['number_of_purchase'];
    itemOut = attributes['item_out'];
    purchaseTotal =
        Money.tryParse(attributes['purchase_total']) ?? const Money(0);
    grossProfit = Money.tryParse(attributes['gross_profit']) ?? const Money(0);
    lastPurchaseDate = DateTime.tryParse(
      attributes['last_purchase_date'] ?? '',
    );
    item =
        ItemClass().findRelationData(
          relation: json['relationships']?['item'],
          included: included,
        ) ??
        Item(id: itemCode, code: itemCode, name: itemName);
    itemType =
        ItemTypeClass().findRelationData(
          relation: json['relationships']?['item_type'],
          included: included,
        ) ??
        ItemType(
          id: itemTypeName,
          name: itemTypeName,
          description: itemTypeDesc,
        );
    brand =
        BrandClass().findRelationData(
          relation: json['relationships']?['brand'],
          included: included,
        ) ??
        Brand(id: brandName, name: brandName ?? '');
    supplier =
        SupplierClass().findRelationData(
          relation: json['relationships']?['supplier'],
          included: included,
        ) ??
        Supplier(id: supplierCode, code: supplierCode, name: supplierName);
  }

  @override
  Map<String, dynamic> toMap() => {
    'item_code': itemCode,
    'item_name': itemName,
    'item': item,
    'supplier': supplier,
    'item_type': itemType,
    'brand': brand,
    'item_type_name': itemTypeName,
    'item_type_desc': itemTypeDesc,
    'supplier_code': supplierCode,
    'supplier_name': supplierName,
    'store_stock': storeStock,
    'margin': margin,
    'limit_profit_discount': limitProfitDiscount,
    'is_consignment': isConsignment,
    'warehouse_stock': warehouseStock,
    'brand_name': brandName,
    'percentage_sales': percentageSales,
    'sell_price': sellPrice,
    'avg_buy_price': avgBuyPrice,
    'last_buy_price': lastBuyPrice,
    'number_of_sales': numberOfSales,
    'sales_total': salesTotal,
    'number_of_purchase': numberOfPurchase,
    'purchase_total': purchaseTotal,
    'last_purchase_date': lastPurchaseDate,
    'item_out': itemOut,
    'gross_profit': grossProfit,
    'stock_left': stockLeft,
    'cogs': cogs,
    'qty_return': numberOfReturn,
  };

  @override
  String get modelValue => itemCode;
  @override
  String get valueDescription => itemName;
}

class ItemReportClass extends ModelClass<ItemReport> {
  @override
  ItemReport initModel() => ItemReport();
}
