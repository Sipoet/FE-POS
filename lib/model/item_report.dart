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
  Percentage? percentageSales;
  Money sellPrice;
  Money avgBuyPrice;
  int numberOfSales;
  int storeStock;
  int warehouseStock;
  double stockLeft;
  Money salesTotal;
  int numberOfPurchase;
  int inventoryDisrepancy;
  Money purchaseTotal;
  Money grossProfit;
  int itemOut;
  bool isConsignment;
  DateTime? lastPurchaseDate;
  Item item;
  IposSupplier supplier;
  IposBrand brand;
  ItemType itemType;
  Money cogs;
  Money lastBuyPrice;
  Percentage? margin;
  Percentage? limitProfitDiscount;
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
    IposSupplier? supplier,
    Item? item,
    IposBrand? brand,
    this.storeStock = 0,
    this.warehouseStock = 0,
    this.inventoryDisrepancy = 0,
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
       supplier = supplier ?? IposSupplier(id: supplierCode),
       itemType = itemType ?? ItemType(id: itemTypeName),
       brand = brand ?? IposBrand(id: brandName);

  @override
  String get path => 'item_reports';
  @override
  String get modelName => 'item_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    id = json['id'];
    itemCode = attributes['item_code'];
    itemName = attributes['item_name'];
    itemTypeName = attributes['item_type_name'] ?? '';
    itemTypeDesc = attributes['item_type_desc'] ?? '';
    supplierCode = attributes['supplier_code'] ?? '';
    supplierName = attributes['supplier_name'] ?? '';
    storeStock = attributes['store_stock'] ?? storeStock;
    warehouseStock = attributes['warehouse_stock'] ?? warehouseStock;
    brandName = attributes['brand_name'] ?? '';
    isConsignment = attributes['is_consignment'] ?? isConsignment;
    stockLeft = double.tryParse(attributes['stock_left']) ?? 0;
    percentageSales = Percentage.tryParse(attributes['percentage_sales']);
    margin = Percentage.tryParse(attributes['margin']);
    limitProfitDiscount = Percentage.tryParse(
      attributes['limit_profit_discount'],
    );

    cogs = Money.parse(attributes['cogs'] ?? '0');
    numberOfReturn = attributes['qty_return'] ?? 0;
    sellPrice = Money.tryParse(attributes['sell_price']) ?? const Money(0);
    avgBuyPrice = Money.tryParse(attributes['avg_buy_price']) ?? const Money(0);
    numberOfSales = attributes['number_of_sales'] ?? 0;
    salesTotal = Money.tryParse(attributes['sales_total']) ?? const Money(0);
    numberOfPurchase = attributes['number_of_purchase'] ?? 0;
    inventoryDisrepancy = attributes['inventory_disrepancy'] ?? 0;
    itemOut = attributes['item_out'] ?? 0;
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
        IposBrandClass().findRelationData(
          relation: json['relationships']?['brand'],
          included: included,
        ) ??
        IposBrand(id: brandName, name: brandName ?? '');
    supplier =
        IposSupplierClass().findRelationData(
          relation: json['relationships']?['supplier'],
          included: included,
        ) ??
        IposSupplier(id: supplierCode, code: supplierCode, name: supplierName);
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
    'inventory_disrepancy': inventoryDisrepancy,
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
