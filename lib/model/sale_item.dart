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
  String saleType;
  Money cogs;
  String? saleCode;
  String? brandName;
  String? supplierCode;
  String? itemTypeName;
  String? itemName;
  DateTime transactionDate;
  SaleItem({
    Item? item,
    super.id,
    this.itemCode = '',
    this.row = 0,
    this.quantity = 0,
    this.price = const Money(0),
    this.uom = '',
    this.saleType = '',
    this.itemName,
    super.createdAt,
    super.updatedAt,
    this.itemTypeName,
    this.brandName,
    this.supplierCode,
    DateTime? transactionDate,
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
    this.cogs = const Money(0),
  }) : item = item ?? Item(),
       transactionDate = transactionDate ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() => {
    'kodeitem': itemCode,
    'item_code': itemCode,
    'item': item,
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
    'sale_type': saleType,
    'item_type_name': itemTypeName,
    'supplier_code': supplierCode,
    'brand_name': brandName,
    'item_name': itemName,
    'transaction_date': transactionDate,
  };

  @override
  String get modelName => 'sale_item';
  @override
  String get path => 'ipos/sale_items';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      item =
          ItemClass().findRelationData(
            included: included,
            relation: json['relationships']?['item'],
          ) ??
          Item();
      promoItem = ItemClass().findRelationData(
        included: included,
        relation: json['relationships']?['promo_item'],
      );
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
    saleType = attributes['sale_type'] ?? '';
    systemSellPrice = attributes['sistemhargajual'] ?? '';
    promoType = attributes['tipepromo'] ?? '';
    promoItemCode = attributes['itempromo'] ?? '';
    promoUom = attributes['satuanpromo'] ?? '';
    saleCode = attributes['notransaksi'] ?? '';
    itemTypeName = attributes['item_type_name'] ?? '';
    supplierCode = attributes['supplier_code'] ?? '';
    brandName = attributes['brand_name'] ?? '';
    itemName = attributes['item_name'] ?? '';
    freeQuantity = double.tryParse(attributes['jmlgratis']) ?? 0;
    cogs = Money.parse(attributes['hppdasar']);
    transactionDate = DateTime.parse(attributes['transaction_date']);
  }

  @override
  String get modelValue => id.toString();
}

class SaleItemClass extends ModelClass<SaleItem> {
  @override
  SaleItem initModel() => SaleItem();
}
