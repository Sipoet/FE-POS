import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PurchaseItem extends Model {
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
  PurchaseItem(
      {Item? item,
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
      this.itemTypeName,
      this.brandName,
      this.supplierCode,
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
      this.cogs = const Money(0)})
      : item = item ?? Item();

  @override
  Map<String, dynamic> toMap() => {
        'kodeitem': itemCode,
        'item_code': itemCode,
        'item_name': item.name,
        'jumlah': quantity,
        'nobaris': row,
        'harga': price,
        'satuan': uom,
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
      };
  Money get sellPrice => item.sellPrice;
  @override
  factory PurchaseItem.fromJson(Map<String, dynamic> json,
      {PurchaseItem? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= PurchaseItem();
    if (included.isNotEmpty) {
      model.item = Model.findRelationData<Item>(
              included: included,
              relation: json['relationships']?['item'],
              convert: Item.fromJson) ??
          Item();
    }
    model.id = json['id'];
    model.itemCode = attributes['kodeitem'];
    model.row = attributes['nobaris'];
    model.quantity = double.parse(attributes['jumlah']);
    model.stockLeft = double.tryParse(attributes['stock_left'] ?? '');
    model.warehouseStock = double.tryParse(attributes['warehouse_stock'] ?? '');
    model.storeStock = double.tryParse(attributes['store_stock'] ?? '');
    model.numberOfSales = double.tryParse(attributes['number_of_sales'] ?? '');
    model.price = Money.parse(attributes['harga']);
    model.uom = attributes['satuan'];
    model.subtotal = Money.parse(attributes['subtotal']);
    model.discountAmount1 = double.parse(attributes['potongan']);
    model.discountPercentage2 = Percentage.parse(attributes['potongan2']);
    model.discountPercentage3 = Percentage.parse(attributes['potongan3']);
    model.discountPercentage4 = Percentage.parse(attributes['potongan4']);
    model.taxAmount = Money.parse(attributes['pajak']);
    model.total = Money.parse(attributes['total']);
    model.productionCode = attributes['production_code'];
    model.expiredDate = DateTime.tryParse(attributes['tglexp'] ?? '');
    model.orderQuantity = double.tryParse(attributes['jmlpesan'] ?? '') ?? 0;
    model.cogs = Money.parse(attributes['hppdasar']);
    model.itemTypeName = attributes['item_type_name'];
    model.supplierCode = attributes['supplier_code'];
    model.brandName = attributes['brand_name'];
    model.purchaseCode = attributes['notransaksi'];
    Model.fromModel(model, attributes);
    return model;
  }

  @override
  String get modelValue => id.toString();
}
