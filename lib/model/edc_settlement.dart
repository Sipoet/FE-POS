import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/payment_provider.dart';
import 'package:fe_pos/model/payment_type.dart';
export 'package:fe_pos/model/payment_provider.dart';
export 'package:fe_pos/model/payment_type.dart';

class EdcSettlement extends Model {
  PaymentProvider paymentProvider;
  PaymentType paymentType;
  Money amount;
  Money diffAmount;
  String merchantId;
  String terminalId;
  dynamic cashierSessionId;
  EdcSettlement({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.cashierSessionId,
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
        'payment_provider.code': paymentProvider.code,
        'payment_type.name': paymentType.name,
        'amount': amount,
        'diff_amount': diffAmount,
        'merchant_id': merchantId,
        'terminal_id': terminalId,
        'cashier_session_id': cashierSessionId,
      };

  @override
  factory EdcSettlement.fromJson(Map<String, dynamic> json,
      {EdcSettlement? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= EdcSettlement();
    model.id = json['id'];
    model.merchantId = attributes['merchant_id'] ?? '';
    model.terminalId = attributes['terminal_id'];
    model.amount = Money.parse(attributes['amount']);
    model.diffAmount = Money.parse(attributes['diff_amount']);
    model.cashierSessionId = attributes['cashier_session_id'];

    return model;
  }
}
