import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PurchaseReturnItem extends Model {
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
  Money sellPrice;
  Money cogs;
  DateTime? expiredDate;
  String? productionCode;
  String? purchaseCode;
  String? brandName;
  String? supplierCode;
  String? itemTypeName;
  PurchaseReturnItem(
      {Item? item,
      super.id,
      this.purchaseCode,
      this.itemCode = '',
      this.row = 0,
      this.quantity = 0,
      this.price = const Money(0),
      this.uom = '',
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
      this.sellPrice = const Money(0),
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

  @override
  String get modelName => 'purchase_return_item';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);

    if (included.isNotEmpty) {
      item = ItemClass().findRelationData(
            included: included,
            relation: json['relationships']?['item'],
          ) ??
          Item();
    }
    id = json['id'];
    itemCode = attributes['kodeitem'];
    row = attributes['nobaris'];
    quantity = double.parse(attributes['jumlah']);
    price = Money.parse(attributes['harga']);
    uom = attributes['satuan'];
    subtotal = Money.parse(attributes['subtotal']);
    discountAmount1 = double.parse(attributes['potongan']);
    discountPercentage2 = Percentage.parse(attributes['potongan2']);
    discountPercentage3 = Percentage.parse(attributes['potongan3']);
    discountPercentage4 = Percentage.parse(attributes['potongan4']);
    taxAmount = Money.parse(attributes['pajak']);
    total = Money.parse(attributes['total']);
    sellPrice = Money.parse(attributes['sell_price']);
    productionCode = attributes['production_code'];
    expiredDate = DateTime.tryParse(attributes['tglexp'] ?? '');
    orderQuantity = double.tryParse(attributes['jmlpesan'] ?? '') ?? 0;
    cogs = Money.parse(attributes['hppdasar']);
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];
    purchaseCode = attributes['notransaksi'];
  }

  @override
  String get modelValue => id.toString();
}

class PurchaseReturnItemClass extends ModelClass<PurchaseReturnItem> {
  @override
  PurchaseReturnItem initModel() => PurchaseReturnItem();
}
