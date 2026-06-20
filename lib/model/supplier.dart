import 'package:fe_pos/model/account.dart';
export 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/contact_number.dart';
export 'package:fe_pos/model/contact_number.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Supplier extends Model with SaveNDestroyModel {
  String? code;
  String name;
  String? bank;
  Account? account;
  String? email;
  String? bankRegisterName;
  String? bankAccountNumber;
  String? address;
  String? city;
  String? description;
  List<Tagging> taggings = [];
  List<ContactNumber> contactNumbers = [];
  Supplier({
    this.name = '',
    this.email,
    super.id,
    this.code,
    this.bank,
    this.account,
    this.bankAccountNumber,
    List<ContactNumber>? contactNumbers,
    List<Tagging>? taggings,
    this.bankRegisterName,
    this.address,
    this.city,
    this.description,
  }) : contactNumbers = contactNumbers ?? [],
       taggings = taggings ?? [];

  @override
  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'bank': bank,
    'account': account,
    'email': email,
    'account_id': account?.id,
    'bank_register_name': bankRegisterName,
    'bank_account_number': bankAccountNumber,
    'bank_account': bankRegisterName,
    'address': address,
    'city': city,
    'description': description,
    'contact_numbers_attributes': contactNumbers
        .map((e) => e.asJson())
        .toList(),
    'taggings_attributes': taggings.map((e) => e.asJson()).toList(),
  };

  void setTags(List<Tag> newTags) {
    int index = 0;
    while (newTags.length > index || taggings.length > index) {
      final tagging = taggings.elementAtOrNull(index);
      final tag = newTags.elementAtOrNull(index);
      if (tagging == null) {
        taggings.add(Tagging(tag: tag));
      } else if (tag == null) {
        tagging.flagDestroy();
      } else {
        tagging.tag = tag;
      }
      index++;
    }
  }

  @override
  String get path => 'suppliers';

  List<Tag> get tags =>
      taggings.where((e) => e.tag != null).map<Tag>((e) => e.tag!).toList();

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    name = attributes['name'] ?? '';
    code = attributes['code'];
    bank = attributes['bank'];
    account = AccountClass().findRelationData(
      included: included,
      relation: json['relationships']?['account'],
    );
    bankAccountNumber = attributes['bank_account_number'];
    bankRegisterName = attributes['bank_register_name'];
    address = attributes['address'];
    email = attributes['email'];
    city = attributes['city'];
    description = attributes['description'];
    contactNumbers = ContactNumberClass().findRelationsData(
      included: included,
      relation: json['relationships']?['contact_numbers'],
    );
    taggings = TaggingClass().findRelationsData(
      included: included,
      relation: json['relationships']?['taggings'],
    );
  }

  @override
  String get valueDescription => name;
}

class SupplierClass extends ModelClass<Supplier> {
  @override
  Supplier initModel() => Supplier();
}
