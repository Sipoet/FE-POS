import 'package:fe_pos/model/purchase_order_item.dart';
export 'package:fe_pos/model/purchase_order_item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PurchaseOrder extends Model {
  String code;
  String? orderCode;
  String userName;
  List<PurchaseOrderItem> purchaseItems;
  DateTime datetime;
  DateTime deliveredDate;
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
  PurchaseOrder(
      {this.userName = '',
      this.description = '',
      this.totalItem = 0,
      this.code = '',
      this.supplierCode = '',
      this.orderCode,
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
      Supplier? supplier,
      super.id,
      super.createdAt,
      super.updatedAt,
      DateTime? datetime,
      DateTime? deliveredDate,
      List<PurchaseOrderItem>? purchaseItems})
      : purchaseItems = purchaseItems ?? <PurchaseOrderItem>[],
        datetime = datetime ?? DateTime.now(),
        supplier = supplier ?? Supplier(),
        deliveredDate = deliveredDate ?? DateTime.now();

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
        'notrsorder': orderCode,
        'kodekantor': location,
        'kantortujuan': destLocation,
        'kodesupel': supplierCode,
        'tanggalkirim': deliveredDate,
      };

  String get supplierName => supplier.name;

  @override
  String get modelName => 'purchase_order';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      purchaseItems = PurchaseOrderItemClass().findRelationsData(
        included: included,
        relation: json['relationships']['purchase_order_items'],
      );
      supplier = SupplierClass().findRelationData(
            included: included,
            relation: json['relationships']['supplier'],
          ) ??
          supplier;
    }
    id = json['id'];
    userName = attributes['user1'];
    datetime = DateTime.parse(attributes['tanggal']);
    deliveredDate = DateTime.parse(attributes['tanggalkirim']);
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

class PurchaseOrderClass extends ModelClass<PurchaseOrder> {
  @override
  PurchaseOrder initModel() => PurchaseOrder();
}
