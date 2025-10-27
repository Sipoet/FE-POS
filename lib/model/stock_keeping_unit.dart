import 'package:fe_pos/model/model.dart';

class StockKeepingUnit extends Model {
  String barcode;
  String description;
  Date prodDate;
  Date? expiredDate;
  double quantity;
  Money cogs;
  Money sellPrice;

  StockKeepingUnit(
      {super.id,
      super.createdAt,
      super.updatedAt,
      this.barcode = '',
      Date? prodDate,
      this.expiredDate,
      this.quantity = 0,
      this.cogs = const Money(0),
      this.sellPrice = const Money(0),
      this.description = ''})
      : prodDate = prodDate ?? Date.today();

  @override
  Map<String, dynamic> toMap() =>
      {'barcode': barcode, 'description': description};

  @override
  String get modelName => 'stock_keeping_unit';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'] ?? {};
    barcode = attributes['barcode'] ?? '';
    description = attributes['description'] ?? '';
    prodDate = Date.tryParse(attributes['prod_date'] ?? '') ?? prodDate;
    expiredDate = Date.tryParse(attributes['expired_date'] ?? '');
    cogs = Money.tryParse(attributes['cogs'] ?? '') ?? cogs;
    quantity = double.tryParse(attributes['quantity'] ?? '') ?? quantity;
    sellPrice = Money.tryParse(attributes['sell_price'] ?? '') ?? sellPrice;
  }
}

class StockKeepingUnitClass extends ModelClass<StockKeepingUnit>
    with FindModel<StockKeepingUnit> {
  @override
  StockKeepingUnit initModel() => StockKeepingUnit();
}
