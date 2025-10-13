import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ActivityLog extends Model {
  String actor;
  String event;
  String description;
  int itemId;
  String itemType;
  ActivityLog(
      {super.id,
      super.createdAt,
      required this.itemId,
      required this.itemType,
      required this.actor,
      required this.event,
      required this.description});

  @override
  Map<String, dynamic> toMap() => {
        'whodunit': actor,
        'created_at': createdAt,
        'event': event,
        'description': description
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    itemId = attributes['item_id'];
    itemType = attributes['item_type'];
    actor = attributes['actor'] ?? 'Script';
    description = attributes['description'];
    createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    event = attributes['event'];
  }

  @override
  String get modelValue => '$event - $itemType - ${id.toString()}';
}

class ActivityLogClass extends ModelClass<ActivityLog> {
  @override
  ActivityLog initModel() => ActivityLog(
      itemId: 0, itemType: '', actor: '', event: '', description: '');
}
