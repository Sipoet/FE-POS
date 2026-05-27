import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/model.dart';

class Location extends Model {
  String name;
  String? address;
  String? city;
  String? country;
  String? postalCode;
  String? state;
  double? long;
  double? lat;
  Account? account;
  Location({
    super.id,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.state,
    this.long,
    this.lat,
    this.account,

    this.name = '',
  });

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    address = attributes['address'];
    name = attributes['name'];
    city = attributes['city'];
    country = attributes['country'];
    postalCode = attributes['postal_code'];
    state = attributes['state'];
    long = double.tryParse(attributes['long'] ?? '');
    long = double.tryParse(attributes['lat'] ?? '');

    account = AccountClass().findRelationData(
      included: included,
      relation: json['relationships']?['account'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'address': address,
    'name': name,
    'city': city,
    'country': country,
    'state': state,
    'postal_code': postalCode,
    'long': long,
    'lat': lat,
    'account': account,
    'account_id': account?.id,
  };

  @override
  String get modelValue => name;
}

class LocationClass extends ModelClass<Location> {
  @override
  Location initModel() => Location();
}
