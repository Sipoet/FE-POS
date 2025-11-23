import 'package:fe_pos/model/sale_item.dart';
export 'package:fe_pos/model/sale_item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Sale extends Model {
  String code;
  String userName;
  List<SaleItem> saleItems;
  DateTime datetime;
  String description;
  double totalItem;
  Money subtotal;
  Money grandtotal;
  Money discountAmount;
  Money otherCost;
  Money? cashAmount;
  Money? debitCardAmount;
  Money? creditCardAmount;
  Money? emoneyAmount;
  String paymentMethodType;
  String taxType;
  Money? taxAmount;
  String bankCode;
  Sale(
      {this.userName = '',
      this.description = '',
      this.totalItem = 0,
      this.code = '',
      this.subtotal = const Money(0),
      this.grandtotal = const Money(0),
      this.discountAmount = const Money(0),
      this.otherCost = const Money(0),
      this.cashAmount = const Money(0),
      this.debitCardAmount = const Money(0),
      this.creditCardAmount = const Money(0),
      this.emoneyAmount = const Money(0),
      this.taxAmount = const Money(0),
      this.paymentMethodType = 'non',
      this.bankCode = '',
      this.taxType = '',
      super.id,
      super.createdAt,
      super.updatedAt,
      DateTime? datetime,
      List<SaleItem>? saleItems})
      : saleItems = saleItems ?? <SaleItem>[],
        datetime = datetime ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() => {
        'user1': userName,
        'tanggal': datetime,
        'keterangan': description,
        'totalitem': totalItem,
        'subtotal': subtotal,
        'totalakhir': grandtotal,
        'potnomfaktur': discountAmount,
        'biayalain': otherCost,
        'jmltunai': cashAmount,
        'jmldebit': debitCardAmount,
        'jmlkk': creditCardAmount,
        'jmlemoney': emoneyAmount,
        'payment_type': paymentMethodType,
        'ppn': taxType,
        'pajak': taxAmount,
        'bank_code': bankCode,
        'notransaksi': code,
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    if (included.isNotEmpty) {
      saleItems = SaleItemClass().findRelationsData(
        included: included,
        relation: json['relationships']['sale_items'],
      );
    }
    id = json['id'];
    userName = attributes['user1'];
    datetime = DateTime.parse(attributes['tanggal']);
    description = attributes['keterangan'];
    totalItem = double.parse(attributes['totalitem']);
    subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    grandtotal = Money.tryParse(attributes['totalakhir']) ?? const Money(0);
    discountAmount =
        Money.tryParse(attributes['potnomfaktur']) ?? const Money(0);
    otherCost = Money.tryParse(attributes['biayalain']) ?? const Money(0);
    cashAmount = Money.tryParse(attributes['jmltunai']) ?? const Money(0);
    debitCardAmount = Money.tryParse(attributes['jmldebit']) ?? const Money(0);
    creditCardAmount = Money.tryParse(attributes['jmlkk']) ?? const Money(0);
    emoneyAmount = Money.tryParse(attributes['jmlemoney']) ?? const Money(0);
    paymentMethodType = attributes['payment_type'] ?? '';
    taxType = attributes['ppn'];
    taxAmount = Money.tryParse(attributes['pajak']) ?? const Money(0);
    code = attributes['notransaksi'];
    bankCode = attributes['bank_code'] ?? '';
  }

  @override
  String get modelValue => code;
}

class SaleClass extends ModelClass<Sale> {
  @override
  Sale initModel() => Sale();
}
