import 'package:fe_pos/model/purchase_item.dart';
export 'package:fe_pos/model/purchase_item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ConsignmentIn extends Model {
  String code;
  String? orderCode;
  String userName;
  List<PurchaseItem> purchaseItems;
  DateTime datetime;
  DateTime? noteDate;
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
  String? bankCode;
  String location;
  String destLocation;
  String supplierCode;
  Supplier supplier;
  ConsignmentIn(
      {this.userName = '',
      this.description = '',
      this.totalItem = 0,
      this.code = '',
      this.supplierCode = '',
      this.orderCode,
      this.noteDate,
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
      this.location = '',
      this.destLocation = '',
      this.bankCode,
      this.taxType = '',
      super.id,
      super.createdAt,
      super.updatedAt,
      Supplier? supplier,
      DateTime? datetime,
      List<PurchaseItem>? purchaseItems})
      : purchaseItems = purchaseItems ?? <PurchaseItem>[],
        supplier = supplier ?? Supplier(),
        datetime = datetime ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() => {
        'user1': userName,
        'tanggal': datetime,
        'note_date': noteDate,
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
        'notrsorder': orderCode,
        'kodekantor': location,
        'kantortujuan': destLocation,
        'kodesupel': supplierCode,
      };

  String get supplierName => supplier.name;

  @override
  factory ConsignmentIn.fromJson(Map<String, dynamic> json,
      {ConsignmentIn? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= ConsignmentIn(userName: '');
    if (included.isNotEmpty) {
      model.purchaseItems = Model.findRelationsData<PurchaseItem>(
          included: included,
          relation: json['relationships']['purchase_items'],
          convert: PurchaseItem.fromJson);
      model.supplier = Model.findRelationData<Supplier>(
              included: included,
              relation: json['relationships']['supplier'],
              convert: Supplier.fromJson) ??
          model.supplier;
    }
    Model.fromModel(model, attributes);
    model.id = json['id'];
    model.userName = attributes['user1'];
    model.datetime = DateTime.parse(attributes['tanggal']);
    model.noteDate = DateTime.tryParse(attributes['note_date']);
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
    model.orderCode = attributes['notrsorder'];
    model.location = attributes['kodekantor'];
    model.destLocation = attributes['kantortujuan'];
    model.bankCode = attributes['bank_code'];
    model.supplierCode = attributes['kodesupel'];
    return model;
  }

  @override
  String get modelValue => code;
}
