import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class SaleItem extends Model {
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
  String systemSellPrice;
  String promoType;
  double freeQuantity;
  String promoItemCode;
  Item? promoItem;
  String promoUom;
  Money cogs;
  String? saleCode;
  String? brandName;
  String? supplierCode;
  String? itemTypeName;
  String? itemName;
  SaleItem(
      {Item? item,
      super.id,
      this.itemCode = '',
      this.row = 0,
      this.quantity = 0,
      this.price = const Money(0),
      this.uom = '',
      this.itemName,
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
      this.systemSellPrice = '',
      this.promoType = '',
      this.freeQuantity = 0,
      this.promoItemCode = '',
      this.promoUom = '',
      this.saleCode,
      this.cogs = const Money(0)})
      : item = item ?? Item();

  @override
  Map<String, dynamic> toMap() => {
        'kodeitem': itemCode,
        'item.namaitem': itemName,
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
        'notransaksi': saleCode,
        'sistemhargajual': systemSellPrice,
        'tipepromo': promoType,
        'jmlgratis': freeQuantity,
        'itempromo': promoItemCode,
        'satuanpromo': promoUom,
        'hppdasar': cogs,
        'item.jenis': itemTypeName,
        'item.supplier1': supplierCode,
        'item.merek': brandName,
        'item_type_name': itemTypeName,
        'supplier_code': supplierCode,
        'brand_name': brandName,
      };

  @override
  factory SaleItem.fromJson(Map<String, dynamic> json,
      {SaleItem? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= SaleItem();
    if (included.isNotEmpty) {
      model.item = Model.findRelationData<Item>(
              included: included,
              relation: json['relationships']?['item'],
              convert: Item.fromJson) ??
          Item();
      model.promoItem = Model.findRelationData<Item>(
          included: included,
          relation: json['relationships']?['promo_item'],
          convert: Item.fromJson);
    }
    model.id = json['id'];
    model.itemCode = attributes['kodeitem'];
    model.row = attributes['nobaris'];
    model.quantity = double.parse(attributes['jumlah']);
    model.price = Money.parse(attributes['harga']);
    model.uom = attributes['satuan'];
    model.subtotal = Money.parse(attributes['subtotal']);
    model.discountAmount1 = double.parse(attributes['potongan']);
    model.discountPercentage2 = Percentage.parse(attributes['potongan2']);
    model.discountPercentage3 = Percentage.parse(attributes['potongan3']);
    model.discountPercentage4 = Percentage.parse(attributes['potongan4']);
    model.taxAmount = Money.parse(attributes['pajak']);
    model.total = Money.parse(attributes['total']);
    model.systemSellPrice = attributes['sistemhargajual'];
    model.promoType = attributes['tipepromo'];
    model.promoItemCode = attributes['itempromo'];
    model.promoUom = attributes['satuanpromo'];
    model.saleCode = attributes['notransaksi'];
    model.itemTypeName = attributes['item_type_name'];
    model.supplierCode = attributes['supplier_code'];
    model.brandName = attributes['brand_name'];
    model.itemName = attributes['item_name'];
    model.freeQuantity = double.tryParse(attributes['jmlgratis']) ?? 0;
    model.cogs = Money.parse(attributes['hppdasar']);
    Model.fromModel(model, attributes);
    return model;
  }
}
