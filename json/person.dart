import 'json_convert_content.dart';

part 'person.g.dart';

class Person {
  factory Person.copy(Person entity) => $PersonCopy(entity);

  factory Person.fromJson(Map<String, dynamic> jsonMap) =>
      $PersonFromJson(jsonMap);

  int? code;

  Data? data;

  List<String>? messages;

  int? timestamp;

  Person();
  
  Map<String, dynamic> toJson() => $PersonToJson(this);
}

class Data {
  factory Data.copy(Data entity) => $DataCopy(entity);

  factory Data.fromJson(Map<String, dynamic> jsonMap) => $DataFromJson(jsonMap);

  int? createdAt;

  int? banTime;

  int? banType;

  int? isDevice;

  int? id;

  String? deviceId;

  int? userId;

  String? banReason;

  int? updatedAt;

  Data();
  Map<String, dynamic> toJson() => $DataToJson(this);
}

