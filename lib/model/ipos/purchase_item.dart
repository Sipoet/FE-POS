import 'package:fe_pos/model/consignment_in.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/ipos/purchase_header.dart';
import 'package:fe_pos/model/purchase_return.dart';
export 'package:fe_pos/tool/custom_type.dart';

class IposPurchaseItem extends Model {
  double quantity;
  Item item;
  String itemCode;
  int row;
  Money price;
  String uom;
  Money subtotal;
  double discountAmount1;
  Percentage discountPercentage2;
  Percentage discountPercentage3;
  Percentage discountPercentage4;
  Money taxAmount;
  Money total;
  double orderQuantity;
  Money cogs;
  DateTime? expiredDate;
  String? productionCode;
  String? purchaseCode;
  String? brandName;
  String? supplierCode;
  String? itemTypeName;
  double? stockLeft;
  double? warehouseStock;
  double? storeStock;
  double? numberOfSales;
  IposPurchaseHeader? purchase;
  PurchaseReturn? purchaseReturn;
  ConsignmentIn? consignmentIn;
  String? purchaseType;
  DateTime? transactionDate;
  IposPurchaseItem({
    Item? item,
    super.id,
    this.purchaseCode,
    this.itemCode = '',
    this.row = 0,
    this.quantity = 0,
    this.price = const Money(0),
    this.uom = '',
    this.stockLeft = 0.0,
    this.storeStock = 0.0,
    this.warehouseStock = 0.0,
    this.numberOfSales = 0.0,
    super.createdAt,
    super.updatedAt,
    this.transactionDate,
    this.itemTypeName,
    this.brandName,
    this.purchaseType,
    this.supplierCode,
    this.purchaseReturn,
    this.subtotal = const Money(0),
    this.discountAmount1 = 0,
    this.discountPercentage2 = const Percentage(0),
    this.discountPercentage3 = const Percentage(0),
    this.discountPercentage4 = const Percentage(0),
    this.taxAmount = const Money(0),
    this.total = const Money(0),
    this.orderQuantity = 0,
    this.productionCode,
    this.expiredDate,
    this.purchase,
    this.cogs = const Money(0),
  }) : item = item ?? Item();

  @override
  Map<String, dynamic> toMap() => {
        'kodeitem': itemCode,
        'item_code': itemCode,
        'item_name': item.name,
        'jumlah': quantity,
        'nobaris': row,
        'harga': price,
        'satuan': uom,
        'item': item,
        'purchase': purchase ?? purchaseReturn ?? consignmentIn,
        'subtotal': subtotal,
        'potongan': discountAmount1,
        'potongan2': discountPercentage2,
        'potongan3': discountPercentage3,
        'potongan4': discountPercentage4,
        'pajak': taxAmount,
        'total': total,
        'stock_left': stockLeft,
        'warehouse_stock': warehouseStock,
        'store_stock': storeStock,
        'number_of_sales': numberOfSales,
        'sell_price': sellPrice,
        'jmlpesan': orderQuantity,
        'tglexp': expiredDate,
        'kodeprod': productionCode,
        'hppdasar': cogs,
        'notransaksi': purchaseCode,
        'item.jenis': itemTypeName,
        'item.supplier1': supplierCode,
        'item.merek': brandName,
        'item_type_name': itemTypeName,
        'supplier_code': supplierCode,
        'brand_name': brandName,
        'transaction_date': transactionDate,
      };
  Money get sellPrice => item.sellPrice;

  @override
  String get path => 'ipos/purchase_items';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    super.setFromJson(json, included: included);
    if (included.isNotEmpty) {
      item = ItemClass().findRelationData(
            included: included,
            relation: json['relationships']?['item'],
          ) ??
          Item(id: attributes['kodeitem'], code: attributes['kodeitem']);
      purchase = IposPurchaseHeaderClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase'],
      );
      purchaseReturn = PurchaseReturnClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase_return'],
      );
      consignmentIn = ConsignmentInClass().findRelationData(
        included: included,
        relation: json['relationships']?['consignment_in'],
      );
    }
    itemCode = attributes['kodeitem'];
    row = attributes['nobaris'];
    quantity = double.parse(attributes['jumlah']);
    stockLeft = double.tryParse(attributes['stock_left'] ?? '');
    warehouseStock = double.tryParse(attributes['warehouse_stock'] ?? '');
    storeStock = double.tryParse(attributes['store_stock'] ?? '');
    numberOfSales = double.tryParse(attributes['number_of_sales'] ?? '');
    price = Money.parse(attributes['harga']);
    uom = attributes['satuan'];
    subtotal = Money.parse(attributes['subtotal']);
    discountAmount1 = double.parse(attributes['potongan']);
    discountPercentage2 = Percentage.parse(attributes['potongan2']);
    discountPercentage3 = Percentage.parse(attributes['potongan3']);
    discountPercentage4 = Percentage.parse(attributes['potongan4']);
    taxAmount = Money.parse(attributes['pajak']);
    total = Money.parse(attributes['total']);
    productionCode = attributes['production_code'];
    expiredDate = DateTime.tryParse(attributes['tglexp'] ?? '');
    orderQuantity = double.tryParse(attributes['jmlpesan'] ?? '') ?? 0;
    cogs = Money.parse(attributes['hppdasar']);
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];
    purchaseCode = attributes['notransaksi'];
    purchaseType = attributes['purchase_type'];
    transactionDate = DateTime.tryParse(attributes['transaction_date'] ?? '');
  }

  String get purchaseTypeName {
    switch (purchaseType) {
      case 'BL':
        return 'Beli';
      case 'RB':
        return 'Retur';
      case 'IM':
        return 'Item Masuk';
      case 'RKI':
        return 'Konsinyasi Retur';
      case 'KI':
        return 'Konsinyasi';
      default:
        return '';
    }
  }

  @override
  String get modelValue => "$purchaseCode-$itemCode";

  @override
  String? get valueDescription => purchaseTypeName;
}

class IposPurchaseItemClass extends ModelClass<IposPurchaseItem> {
  @override
  IposPurchaseItem initModel() => IposPurchaseItem();
}
