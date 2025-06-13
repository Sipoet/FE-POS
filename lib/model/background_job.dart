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
  factory BackgroundJob.fromJson(Map<String, dynamic> json,
      {BackgroundJob? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= BackgroundJob();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.jobClass = attributes['job_class'] ?? '';
    model.args = attributes['args'].toString();
    model.description = attributes['description'].toString();
    model.status = BackgroundJobStatus.fromString(attributes['status']);
    return model;
  }

  @override
  String get modelValue => '$jobClass - $args';
}
