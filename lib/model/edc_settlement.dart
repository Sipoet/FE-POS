import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/payment_provider.dart';
import 'package:fe_pos/model/payment_type.dart';
export 'package:fe_pos/model/payment_provider.dart';
export 'package:fe_pos/model/payment_type.dart';

enum EdcSettlementStatus implements EnumTranslation {
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

  factory EdcSettlementStatus.fromString(String value) {
    if (value == 'draft') {
      return draft;
    } else if (value == 'verified') {
      return verified;
    }
    throw '$value is not valid employee status';
  }

  @override
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
  }) : paymentProvider = paymentProvider ?? PaymentProvider(),
       paymentType = paymentType ?? PaymentType();

  @override
  Map<String, dynamic> toMap() => {
    'payment_provider.name': paymentProvider.name,
    'payment_type.name': paymentType.name,
    'payment_type_id': paymentTypeId,
    'payment_provider_id': paymentProviderId,
    'payment_type': paymentType,
    'payment_provider': paymentProvider,
    'amount': amount,
    'diff_amount': diffAmount,
    'merchant_id': merchantId,
    'terminal_id': terminalId,
    'cashier_session_id': cashierSessionId,
    'status': status,
  };
  @override
  String get modelName => 'edc_settlement';
  dynamic get paymentProviderId => paymentProvider.id;
  dynamic get cashierSessionId => cashierSession?.id;
  dynamic get paymentTypeId => paymentType.id;
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    merchantId = attributes['merchant_id'] ?? '';
    terminalId = attributes['terminal_id'];
    amount = Money.parse(attributes['amount']);
    if (attributes['status'] != null) {
      status = EdcSettlementStatus.fromString(attributes['status']);
    }
    if (attributes['diff_amount'] != null) {
      diffAmount = Money.parse(attributes['diff_amount']);
    }
    paymentType =
        PaymentTypeClass().findRelationData(
          included: included,
          relation: json['relationships']?['payment_type'],
        ) ??
        paymentType;
    paymentProvider =
        PaymentProviderClass().findRelationData(
          included: included,
          relation: json['relationships']?['payment_provider'],
        ) ??
        paymentProvider;
    cashierSession = CashierSessionClass().findRelationData(
      included: included,
      relation: json['relationships']?['cashier_session'],
    );
  }

  @override
  String get modelValue => id.toString();
}

class EdcSettlementClass extends ModelClass<EdcSettlement> {
  @override
  EdcSettlement initModel() => EdcSettlement();
}
