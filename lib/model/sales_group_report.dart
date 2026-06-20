import 'package:fe_pos/model/model.dart';

class SalesGroupReport extends Model {
  String? itemTypeName;
  String? supplierCode;
  String? supplierName;
  String? brandName;
  Percentage salesPercentage;
  int? lastPurchaseYear;
  double numberOfPurchase;
  double numberOfSales;
  double startStock;
  double endStock;
  double numberOfPurchaseReturn;
  double numberOfSalesReturn;
  double numberOfItemOut;
  double numberOfItemIn;
  double numberOfAssembly;
  double numberOfOpname;
  Money salesTotal;
  Money purchaseTotal;
  Money grossProfit;

  SalesGroupReport({
    super.id,
    this.itemTypeName,
    this.supplierCode,
    this.supplierName,
    this.brandName,
    this.lastPurchaseYear,
    this.salesPercentage = const Percentage(0),
    this.numberOfPurchase = 0,
    this.numberOfSales = 0,
    this.startStock = 0,
    this.endStock = 0,
    this.numberOfPurchaseReturn = 0,
    this.numberOfSalesReturn = 0,
    this.numberOfItemOut = 0,
    this.numberOfItemIn = 0,
    this.numberOfAssembly = 0,
    this.numberOfOpname = 0,
    this.salesTotal = const Money(0),
    this.purchaseTotal = const Money(0),
    this.grossProfit = const Money(0),
  });

  String get supplier => "$supplierCode - $supplierName";
  @override
  String get path => 'sales_group_by_suppliers';
  @override
  String get modelName => 'sales_group_by_supplier';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    lastPurchaseYear = attributes['last_purchase_year'];
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    supplierName = attributes['supplier_name'];
    brandName = attributes['brand_name'];
    salesPercentage = Percentage(attributes['sales_percentage'] ?? 0);
    numberOfPurchase = double.parse(
      attributes['number_of_purchase'].toString(),
    );
    numberOfSales = double.parse(attributes['number_of_sales'].toString());
    startStock = double.parse(attributes['start_stock'].toString());
    endStock = double.parse(attributes['end_stock'].toString());
    numberOfPurchaseReturn = double.parse(
      attributes['number_of_purchase_return'].toString(),
    );
    numberOfSalesReturn = double.parse(
      attributes['number_of_sales_return'].toString(),
    );
    numberOfItemOut = double.parse(attributes['number_of_item_out'].toString());
    numberOfItemIn = double.parse(attributes['number_of_item_in'].toString());
    numberOfAssembly = double.parse(
      attributes['number_of_assembly'].toString(),
    );
    numberOfOpname = double.parse(attributes['number_of_opname'].toString());
    grossProfit = Money.tryParse(attributes['gross_profit']) ?? const Money(0);
    salesTotal = Money.tryParse(attributes['sales_total']) ?? const Money(0);
    purchaseTotal =
        Money.tryParse(attributes['purchase_total']) ?? const Money(0);
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
    'start_stock': startStock,
    'end_stock': endStock,
    'supplier': supplier,
    'sales_total': salesTotal,
    'purchase_total': purchaseTotal,
    'gross_profit': grossProfit,
    'last_purchase_year': lastPurchaseYear,
    'number_of_purchase_return': numberOfPurchaseReturn,
    'number_of_item_in': numberOfItemIn,
    'number_of_sales_return': numberOfSalesReturn,
    'number_of_item_out': numberOfItemOut,
    'number_of_assembly': numberOfAssembly,
    'number_of_opname': numberOfOpname,
  };

  @override
  String get modelValue => id.toString();
}

class SalesGroupReportClass extends ModelClass<SalesGroupReport> {
  @override
  SalesGroupReport initModel() => SalesGroupReport();
}
