import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum BackgroundJobStatus {
  scheduled,
  process,
  finished,
  retry,
  dead;

  static BackgroundJobStatus fromString(value) {
    switch (value) {
      case 'scheduled':
        return scheduled;
      case 'process':
        return process;
      case 'finished':
        return finished;
      case 'retry':
        return retry;
      case 'dead':
        return dead;
      default:
        throw 'invalid status $value';
    }
  }

  @override
  String toString() {
    switch (this) {
      case scheduled:
        return 'scheduled';
      case process:
        return 'process';
      case finished:
        return 'finished';
      case retry:
        return 'retry';
      case dead:
        return 'dead';
    }
  }
}

class BackgroundJob extends Model {
  String jobClass;
  String? args;
  BackgroundJobStatus status;
  String description;
  BackgroundJob(
      {this.jobClass = '',
      this.args,
      this.description = '',
      this.status = BackgroundJobStatus.scheduled,
      super.id,
      super.createdAt,
      super.updatedAt});

  @override
  Map<String, dynamic> toMap() => {
        'job_class': jobClass,
        'args': args,
        'status': status,
        'description': description,
      };

  @override
  String get modelName => 'background_job';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    super.setFromJson(json, included: included);
    jobClass = attributes['job_class'] ?? '';
    args = attributes['args'].toString();
    description = attributes['description'].toString();
    status = BackgroundJobStatus.fromString(attributes['status']);
  }

  @override
  String get modelValue => '$jobClass - $args';
}

class BackgroundJobClass extends ModelClass<BackgroundJob> {
  @override
  BackgroundJob initModel() => BackgroundJob();
}
