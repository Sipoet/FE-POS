import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payment_provider_edc.dart';
export 'package:fe_pos/model/payment_provider_edc.dart';

enum PaymentProviderStatus {
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
  factory PaymentProvider.fromJson(Map<String, dynamic> json,
      {PaymentProvider? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PaymentProvider();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.bankOrProvider = attributes['bank_or_provider'] ?? '';
    model.name = attributes['name'] ?? '';
    model.currency = attributes['currency'] ?? 'IDR';
    model.accountNumber = attributes['account_number'] ?? '';
    model.accountRegisterName = attributes['account_register_name'] ?? '';
    model.swiftCode = attributes['swift_code'];
    model.status = PaymentProviderStatus.fromString(attributes['status']);
    model.paymentProviderEdcs = Model.findRelationsData(
        included: included,
        convert: PaymentProviderEdc.fromJson,
        relation: json['relationships']?['payment_provider_edcs']);
    return model;
  }
}
