import 'package:fe_pos/model/model.dart';

class PaymentProvider extends Model {
  String code;
  String name;
  String currency;
  String accountNumber;
  String accountRegisterName;
  String? swiftCode;
  PaymentProvider(
      {this.code = '',
      this.name = '',
      super.id,
      this.currency = 'idr',
      this.accountNumber = '',
      this.accountRegisterName = '',
      this.swiftCode});

  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'currency': currency,
        'account_number': accountNumber,
        'account_register_name': accountRegisterName,
        'swift_code': swiftCode
      };

  @override
  factory PaymentProvider.fromJson(Map<String, dynamic> json,
      {PaymentProvider? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PaymentProvider();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.code = attributes['code'];
    model.name = attributes['name'];
    model.currency = attributes['currency'];
    model.accountNumber = attributes['account_number'];
    model.accountRegisterName = attributes['account_register_name'];
    model.swiftCode = attributes['swift_code'];
    return model;
  }
}
