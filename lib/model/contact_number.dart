import 'package:fe_pos/model/model.dart';

enum ContactPlatform implements EnumTranslation {
  tel,
  whatsapp,
  fax,
  facebook,
  instagram,
  tiktok,
  telegram;

  static ContactPlatform fromString(String value) {
    switch (value) {
      case 'tel':
        return tel;
      case 'whatsapp':
        return whatsapp;
      case 'fax':
        return fax;
      case 'facebook':
        return facebook;
      case 'instagram':
        return instagram;
      case 'tiktok':
        return tiktok;
      case 'telegram':
        return telegram;
      default:
        throw '$value not valid contact platform';
    }
  }

  @override
  String toString() {
    switch (this) {
      case tel:
        return 'tel';
      case whatsapp:
        return 'whatsapp';
      case fax:
        return 'fax';
      case facebook:
        return 'facebook';
      case instagram:
        return 'instagram';
      case tiktok:
        return 'tiktok';
      case telegram:
        return 'telegram';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case tel:
        return 'Telepon';
      case whatsapp:
        return 'Whatsapp';
      case fax:
        return 'Fax';
      case facebook:
        return 'Facebook';
      case instagram:
        return 'Instagram';
      case tiktok:
        return 'Tiktok';
      case telegram:
        return 'Telegram';
    }
  }
}

class ContactNumber extends Model {
  ContactPlatform platform;
  String? name;
  String value;
  ContactNumber({this.platform = .tel, this.value = '', this.name = ''});

  @override
  Map<String, dynamic> toMap() => {
    'platform': platform,
    'name': name,
    'value': value,
  };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    platform = ContactPlatform.fromString(attributes['platform']);
    name = attributes['name'];
    value = attributes['value'];
  }
}

class ContactNumberClass extends ModelClass<ContactNumber> {
  @override
  ContactNumber initModel() => ContactNumber();
}
