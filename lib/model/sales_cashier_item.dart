import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';

class SalesCashierItem extends Model {
  String itemBarcode;
  Item item;
  int quantity;
  String uom;
  Money price;
  Money discountAmount;
  String? promoCode;
  Percentage? discountPercentage;
  DiscountRule? discountRule;
  int? discountRulePriority;
  Date? expiredDate;
  SalesCashierItem(
      {this.itemBarcode = '',
      this.uom = '',
      this.quantity = 0,
      this.price = const Money(0),
      this.discountAmount = const Money(0),
      this.discountPercentage,
      this.expiredDate,
      this.discountRule,
      this.discountRulePriority,
      this.promoCode,
      Item? item,
      super.id,
      super.createdAt,
      super.updatedAt})
      : item = item ?? Item();

  int? get discountRuleId => discountRule?.id;

  String get itemName => item.name;
  @override
  Map<String, dynamic> toMap() => {
        'item_barcode': itemBarcode,
        'item_name': itemName,
        'description': itemName,
        'uom': uom,
        // 'totalitem': totalItem,
        // 'subtotal': subtotal,
        // 'totalakhir': grandtotal,
        // 'potnomfaktur': discountAmount,
        // 'biayalain': otherCost,
        // 'jmltunai': cashAmount,
        // 'jmldebit': debitCardAmount,
        // 'jmlkk': creditCardAmount,
        // 'jmlemoney': emoneyAmount,
        // 'payment_type': paymentMethodType,
        // 'ppn': taxType,
        // 'pajak': taxAmount,
        // 'bank_code': bankCode,
        // 'notransaksi': code,
      };

  String get brandName => item.brandName ?? '';
  String get itemTypeName => item.itemTypeName;
  Money get subtotal => price * quantity;
  Money get total => subtotal - discountAmount;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    itemBarcode = attributes['item_barcode'];
    if (included.isNotEmpty) {
      item = ItemClass().findRelationData(
            included: included,
            relation: json['relationships']['item'],
          ) ??
          item;
    }
    // model.userName = attributes['user1'];
    // model.datetime = DateTime.parse(attributes['tanggal']);
    // model.description = attributes['keterangan'];
    // model.totalItem = double.parse(attributes['totalitem']);
    // model.subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    // model.grandtotal =
    //     Money.tryParse(attributes['totalakhir']) ?? const Money(0);
    // model.discountAmount =
    //     Money.tryParse(attributes['potnomfaktur']) ?? const Money(0);
    // model.otherCost = Money.tryParse(attributes['biayalain']) ?? const Money(0);
    // model.cashAmount = Money.tryParse(attributes['jmltunai']) ?? const Money(0);
    // model.debitCardAmount =
    //     Money.tryParse(attributes['jmldebit']) ?? const Money(0);
    // model.creditCardAmount =
    //     Money.tryParse(attributes['jmlkk']) ?? const Money(0);
    // model.emoneyAmount =
    //     Money.tryParse(attributes['jmlemoney']) ?? const Money(0);
    // model.paymentMethodType = attributes['payment_type'] ?? '';
    // model.taxType = attributes['ppn'];
    // model.taxAmount = Money.tryParse(attributes['pajak']) ?? const Money(0);
    // model.code = attributes['notransaksi'];
    // model.bankCode = attributes['bank_code'] ?? '';
  }

  @override
  String get modelValue => id;
}

class SalesCashierItemClass extends ModelClass<SalesCashierItem> {
  @override
  SalesCashierItem initModel() => SalesCashierItem();
}
