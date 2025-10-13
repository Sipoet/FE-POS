import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payment_provider.dart';
import 'package:fe_pos/model/payment_type.dart';
export 'package:fe_pos/model/payment_provider.dart';
export 'package:fe_pos/model/payment_type.dart';

class SalesPayment extends Model {
  PaymentType paymentType;
  PaymentProvider paymentProvider;
  Money amount;
  SalesPayment({
    PaymentProvider? paymentProvider,
    PaymentType? paymentType,
    this.amount = const Money(0),
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : paymentProvider = paymentProvider ?? PaymentProvider(),
        paymentType = paymentType ?? PaymentType();

  @override
  Map<String, dynamic> toMap() => {};

  bool get isCash => paymentType.name.toLowerCase().trim() == 'cash';

  @override
  String get modelName => 'sales_payment';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    amount = Money.parse(attributes['amount']);
    if (included.isNotEmpty) {
      paymentType = PaymentTypeClass().findRelationData(
              included: included,
              relation: json['relationships']['payment_type']) ??
          paymentType;
      paymentProvider = PaymentProviderClass().findRelationData(
            included: included,
            relation: json['relationships']['payment_provider'],
          ) ??
          paymentProvider;
    }
  }

  @override
  String get modelValue => id;
}

class SalesPaymentClass extends ModelClass<SalesPayment> {
  @override
  SalesPayment initModel() => SalesPayment();
}
