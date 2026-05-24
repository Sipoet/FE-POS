import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/model_route.dart';

final route = ModelRoute();

class CostDetail extends Model {
  Money amount;
  int? sourceId;
  String? sourceType;
  String? description;

  CostDetail({
    super.id,
    this.amount = const Money(0),
    this.description,
    this.sourceId,
    this.sourceType,
  });

  @override
  Map<String, dynamic> toMap() => {
    'amount': amount,
    'source_id': sourceId,
    'source_type': sourceType,
    'description': description,
  };

  Model? get source {
    try {
      final model = route.modelClassOf(sourceType!)!.initModel();
      model.id = sourceId;
      return model;
    } catch (e) {
      return null;
    }
  }

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    amount = Money.parse(attributes['amount']);
    sourceId = int.tryParse(attributes['source_id'] ?? '');
    sourceType = attributes['source_type'];
    description = attributes['description'];
  }
}

class CostDetailClass extends ModelClass<CostDetail> {
  @override
  CostDetail initModel() => CostDetail();
}
