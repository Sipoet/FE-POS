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
  String get modelName => 'consignment_in';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      purchaseItems = PurchaseItemClass().findRelationsData(
        included: included,
        relation: json['relationships']['purchase_items'],
      );
      supplier = SupplierClass().findRelationData(
            included: included,
            relation: json['relationships']['supplier'],
          ) ??
          supplier;
    }
    super.setFromJson(json, included: included);
    id = json['id'];
    userName = attributes['user1'];
    datetime = DateTime.parse(attributes['tanggal']);
    noteDate = DateTime.tryParse(attributes['note_date'] ?? '');
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
    orderCode = attributes['notrsorder'];
    location = attributes['kodekantor'];
    destLocation = attributes['kantortujuan'];
    bankCode = attributes['bank_code'];
    supplierCode = attributes['kodesupel'];
  }

  @override
  String get modelValue => code;
}

class ConsignmentInClass extends ModelClass<ConsignmentIn> {
  @override
  ConsignmentIn initModel() => ConsignmentIn();
}
