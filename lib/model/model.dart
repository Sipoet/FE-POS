abstract class Model {
  Map<String, dynamic> toMap();

  Map<String, dynamic> toJson();
}

abstract class ModelClass {
  Model fromJson(Map<String, dynamic> json);
}
