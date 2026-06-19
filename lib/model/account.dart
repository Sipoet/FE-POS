import 'package:fe_pos/model/model.dart';

enum AccountType implements EnumTranslation {
  asset,
  liability,
  expense,
  income,
  equity;

  static AccountType fromString(String value) {
    switch (value) {
      case 'equity':
        return equity;
      case 'income':
        return income;
      case 'expense':
        return expense;
      case 'liability':
        return liability;
      case 'asset':
        return asset;
      default:
        throw '$value not valid account type';
    }
  }

  @override
  String toString() {
    switch (this) {
      case equity:
        return 'equity';
      case income:
        return 'income';
      case expense:
        return 'expense';
      case liability:
        return 'liability';
      case asset:
        return 'asset';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case equity:
        return 'Ekuitas';
      case income:
        return 'Pendapatan';
      case expense:
        return 'Biaya';
      case liability:
        return 'Kewajiban';
      case asset:
        return 'Aset';
    }
  }
}

class Account extends Model {
  String name;
  bool isHeader;
  AccountType accountType;
  Account? parent;
  Account({
    super.id,
    this.parent,
    this.isHeader = false,
    super.createdAt,
    super.updatedAt,
    this.name = '',
    this.accountType = .asset,
  });

  @override
  String get path => 'ipos/accounts';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];

    name = attributes['name'];

    parent = AccountClass().findRelationData(
      included: included,
      relation: json['relationships']?['parent'],
    );
    isHeader = attributes['is_header'] == true;
  }

  int? get parentId => parent?.id as int;
  @override
  Map<String, dynamic> toMap() => {
    'is_header': isHeader,
    'name': name,
    'parent_id': parent?.id,
    'account_type': accountType,
    'parent': parent,
  };

  @override
  String get modelValue => name;
}

class AccountClass extends ModelClass<Account> {
  @override
  Account initModel() => Account();
}
