import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/payment_provider.dart';
import 'package:fe_pos/model/payment_type.dart';
export 'package:fe_pos/model/payment_provider.dart';
export 'package:fe_pos/model/payment_type.dart';

enum EdcSettlementStatus {
  draft,
  verified;

  @override
  String toString() {
    if (this == draft) {
      return 'draft';
    } else if (this == verified) {
      return 'verified';
    }
    return '';
  }

  factory EdcSettlementStatus.convertFromString(String value) {
    if (value == 'draft') {
      return draft;
    } else if (value == 'verified') {
      return verified;
    }
    throw '$value is not valid employee status';
  }

  String humanize() {
    if (this == draft) {
      return 'Draft';
    } else if (this == verified) {
      return 'Verified';
    }
    return '';
  }
}

class EdcSettlement extends Model {
  PaymentProvider paymentProvider;
  PaymentType paymentType;
  Money amount;
  Money diffAmount;
  String merchantId;
  String terminalId;
  EdcSettlementStatus status;
  CashierSession? cashierSession;
  EdcSettlement({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.cashierSession,
    this.status = EdcSettlementStatus.draft,
    this.amount = const Money(0),
    this.diffAmount = const Money(0),
    this.merchantId = '',
    this.terminalId = '',
    PaymentProvider? paymentProvider,
    PaymentType? paymentType,
  })  : paymentProvider = paymentProvider ?? PaymentProvider(),
        paymentType = paymentType ?? PaymentType();

  @override
  Map<String, dynamic> toMap() => {
        'payment_provider.name': paymentProvider.name,
        'payment_type.name': paymentType.name,
        'payment_type_id': paymentTypeId,
        'payment_provider_id': paymentProviderId,
        'amount': amount,
        'diff_amount': diffAmount,
        'merchant_id': merchantId,
        'terminal_id': terminalId,
        'cashier_session_id': cashierSessionId,
        'status': status,
      };

  dynamic get paymentProviderId => paymentProvider.id;
  dynamic get cashierSessionId => cashierSession?.id;
  dynamic get paymentTypeId => paymentType.id;
  @override
  factory EdcSettlement.fromJson(Map<String, dynamic> json,
      {EdcSettlement? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= EdcSettlement();
    model.id = json['id'];
    model.merchantId = attributes['merchant_id'] ?? '';
    model.terminalId = attributes['terminal_id'];
    model.amount = Money.parse(attributes['amount']);
    model.status = EdcSettlementStatus.convertFromString(attributes['status']);
    model.diffAmount = Money.parse(attributes['diff_amount']);
    model.paymentType = Model.findRelationData<PaymentType>(
            included: included,
            convert: PaymentType.fromJson,
            relation: json['relationships']?['payment_type']) ??
        model.paymentType;
    model.paymentProvider = Model.findRelationData<PaymentProvider>(
            included: included,
            convert: PaymentProvider.fromJson,
            relation: json['relationships']?['payment_provider']) ??
        model.paymentProvider;
    model.cashierSession = Model.findRelationData<CashierSession>(
        included: included,
        convert: CashierSession.fromJson,
        relation: json['relationships']?['cashier_session']);
    return model;
  }
}
