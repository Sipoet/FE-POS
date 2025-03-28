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
  factory SalesPayment.fromJson(Map<String, dynamic> json,
      {SalesPayment? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= SalesPayment();
    model.amount = Money.parse(attributes['amount']);
    if (included.isNotEmpty) {
      model.paymentType = Model.findRelationData<PaymentType>(
              included: included,
              relation: json['relationships']['payment_type'],
              convert: PaymentType.fromJson) ??
          model.paymentType;
      model.paymentProvider = Model.findRelationData<PaymentProvider>(
              included: included,
              relation: json['relationships']['payment_provider'],
              convert: PaymentProvider.fromJson) ??
          model.paymentProvider;
    }
    Model.fromModel(model, attributes);
    model.id = json['id'];
    return model;
  }

  @override
  String get modelValue => id;
}
