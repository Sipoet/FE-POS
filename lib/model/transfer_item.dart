import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class TransferItem extends Model {
  double quantity;
  Item item;
  String itemCode;
  int row;
  String uom;
  double conversionQuantity;
  Money sellPrice;
  Money cogs;
  DateTime? expiredDate;
  String? productionCode;
  String? detinfo;
  String? transferCode;
  String? brandName;
  String? supplierCode;
  String? itemTypeName;
  TransferItem({
    Item? item,
    super.id,
    this.itemCode = '',
    this.row = 0,
    this.quantity = 0,
    this.uom = '',
    this.detinfo,
    this.transferCode,
    this.itemTypeName,
    this.brandName,
    this.supplierCode,
    this.conversionQuantity = 0,
    super.createdAt,
    super.updatedAt,
    this.productionCode,
    this.expiredDate,
    this.sellPrice = const Money(0),
    this.cogs = const Money(0),
  }) : item = item ?? Item();

  @override
  Map<String, dynamic> toMap() => {
    'kodeitem': itemCode,
    'jumlah': quantity,
    'nobaris': row,
    'satuan': uom,
    'jmlkonversi': conversionQuantity,
    'sell_price': sellPrice,
    'detinfo': detinfo,
    'tglexp': expiredDate,
    'kodeprod': productionCode,
    'cogs': cogs,
    'notransaksi': transferCode,
    'item.jenis': itemTypeName,
    'item.supplier1': supplierCode,
    'item.merek': brandName,
    'item_type_name': itemTypeName,
    'supplier_code': supplierCode,
    'brand_name': brandName,
  };

  @override
  String get path => 'ipos/transfer_items';

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
    }
    id = json['id'];
    itemCode = attributes['kodeitem'];
    row = attributes['nobaris'];
    quantity = double.parse(attributes['jumlah']);
    uom = attributes['satuan'];
    conversionQuantity = double.parse(attributes['jmlkonversi']);
    sellPrice = Money.parse(attributes['sell_price']);
    productionCode = attributes['production_code'];
    expiredDate = DateTime.tryParse(attributes['tglexp'] ?? '');
    detinfo = attributes['detinfo'] ?? 0;
    cogs = Money.parse(attributes['hppdasar'] ?? '0');
    transferCode = attributes['notransaksi'];
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];
  }

  @override
  String get modelValue => id.toString();
}

class TransferItemClass extends ModelClass<TransferItem> {
  @override
  TransferItem initModel() => TransferItem();
}
