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
  factory Sale.fromJson(Map<String, dynamic> json,
      {Sale? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= Sale(userName: '');
    if (included.isNotEmpty) {
      model.saleItems = Model.findRelationsData<SaleItem>(
          included: included,
          relation: json['relationships']['sale_items'],
          convert: SaleItem.fromJson);
    }
    Model.fromModel(model, attributes);
    model.id = json['id'];
    model.userName = attributes['user1'];
    model.datetime = DateTime.parse(attributes['tanggal']);
    model.description = attributes['keterangan'];
    model.totalItem = double.parse(attributes['totalitem']);
    model.subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    model.grandtotal =
        Money.tryParse(attributes['totalakhir']) ?? const Money(0);
    model.discountAmount =
        Money.tryParse(attributes['potnomfaktur']) ?? const Money(0);
    model.otherCost = Money.tryParse(attributes['biayalain']) ?? const Money(0);
    model.cashAmount = Money.tryParse(attributes['jmltunai']) ?? const Money(0);
    model.debitCardAmount =
        Money.tryParse(attributes['jmldebit']) ?? const Money(0);
    model.creditCardAmount =
        Money.tryParse(attributes['jmlkk']) ?? const Money(0);
    model.emoneyAmount =
        Money.tryParse(attributes['jmlemoney']) ?? const Money(0);
    model.paymentMethodType = attributes['payment_type'] ?? '';
    model.taxType = attributes['ppn'];
    model.taxAmount = Money.tryParse(attributes['pajak']) ?? const Money(0);
    model.code = attributes['notransaksi'];
    model.bankCode = attributes['bank_code'] ?? '';
    return model;
  }
}
