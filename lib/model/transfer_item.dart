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
  TransferItem(
      {Item? item,
      super.id,
      this.itemCode = '',
      this.row = 0,
      this.quantity = 0,
      this.uom = '',
      this.detinfo,
      this.transferCode,
      this.conversionQuantity = 0,
      super.createdAt,
      super.updatedAt,
      this.productionCode,
      this.expiredDate,
      this.sellPrice = const Money(0),
      this.cogs = const Money(0)})
      : item = item ?? Item();

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
      };

  @override
  factory TransferItem.fromJson(Map<String, dynamic> json,
      {TransferItem? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= TransferItem();
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
    model.uom = attributes['satuan'];
    model.conversionQuantity = double.parse(attributes['jmlkonversi']);
    model.sellPrice = Money.parse(attributes['sell_price']);
    model.productionCode = attributes['production_code'];
    model.expiredDate = DateTime.tryParse(attributes['tglexp'] ?? '');
    model.detinfo = attributes['detinfo'] ?? 0;
    model.cogs = Money.parse(attributes['hppdasar'] ?? '0');
    model.transferCode = attributes['notransaksi'];
    Model.fromModel(model, attributes);
    return model;
  }
}
