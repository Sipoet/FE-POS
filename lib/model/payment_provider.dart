import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/model/payment_provider_edc.dart';

enum PaymentProviderStatus implements EnumTranslation {
  active,
  inactive;

  @override
  String toString() {
    return super.toString().split('.').last;
  }

  static PaymentProviderStatus fromString(value) {
    switch (value) {
      case 'inactive':
        return inactive;
      case 'active':
        return active;

      default:
        throw 'not valid payslip status';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case inactive:
        return 'Tidak Aktif';
      case active:
        return 'Aktif';
    }
  }
}

class PaymentProvider extends Model {
  String bankOrProvider;
  String name;
  String currency;
  String accountNumber;
  String accountRegisterName;
  PaymentProviderStatus status;
  String? swiftCode;
  List<PaymentProviderEdc> paymentProviderEdcs;
  PaymentProvider(
      {this.bankOrProvider = '',
      this.name = '',
      super.id,
      super.createdAt,
      super.updatedAt,
      this.status = PaymentProviderStatus.inactive,
      List<PaymentProviderEdc>? paymentProviderEdcs,
      this.currency = 'IDR',
      this.accountNumber = '',
      this.accountRegisterName = '',
      this.swiftCode})
      : paymentProviderEdcs = paymentProviderEdcs ?? <PaymentProviderEdc>[];

  @override
  Map<String, dynamic> toMap() => {
        'bank_or_provider': bankOrProvider,
        'name': name,
        'status': status,
        'currency': currency,
        'account_number': accountNumber,
        'account_register_name': accountRegisterName,
        'swift_code': swiftCode,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
  @override
  String get modelName => 'payment_provider';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    bankOrProvider = attributes['bank_or_provider'] ?? '';
    name = attributes['name'] ?? '';
    currency = attributes['currency'] ?? 'IDR';
    accountNumber = attributes['account_number'] ?? '';
    accountRegisterName = attributes['account_register_name'] ?? '';
    swiftCode = attributes['swift_code'];
    status = PaymentProviderStatus.fromString(attributes['status']);
    paymentProviderEdcs = PaymentProviderEdcClass().findRelationsData(
        included: included,
        relation: json['relationships']?['payment_provider_edcs']);
  }

  @override
  String get modelValue => bankOrProvider;
}

class PaymentProviderClass extends ModelClass<PaymentProvider> {
  @override
  PaymentProvider initModel() => PaymentProvider();
}
