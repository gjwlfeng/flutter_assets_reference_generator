part of 'person.dart';

Person $PersonCopy(Person entity) {
  Person person = Person();
  person.code = entity.code;
  person.data = entity.data;
  person.messages = entity.messages;
  person.timestamp = entity.timestamp;
  return person;
}

Map<String, dynamic> $PersonToJson(Person entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data["code"] = entity.code;
  data["data"] = entity.data;
  data["messages"] = entity.messages;
  data["timestamp"] = entity.timestamp;
  return data;
}

Person $PersonFromJson(Map<String, dynamic> jsonMap) {
  Person person = Person();
  int? code = jsonConvert.convert<int>(jsonMap["code"]);
  if (code != null) {
    person.code = code;
  }
  Data? data = jsonConvert.convert<Data>(jsonMap["data"]);
  if (data != null) {
    person.data = data;
  }
  List<String>? messages =
      jsonConvert.convert<List<String>>(jsonMap["messages"]);
  if (messages != null) {
    person.messages = messages;
  }
  int? timestamp = jsonConvert.convert<int>(jsonMap["timestamp"]);
  if (timestamp != null) {
    person.timestamp = timestamp;
  }
  return person;
}

Data $DataCopy(Data entity) {
  Data data = Data();
  data.createdAt = entity.createdAt;
  data.banTime = entity.banTime;
  data.banType = entity.banType;
  data.isDevice = entity.isDevice;
  data.id = entity.id;
  data.deviceId = entity.deviceId;
  data.userId = entity.userId;
  data.banReason = entity.banReason;
  data.updatedAt = entity.updatedAt;
  return data;
}

Map<String, dynamic> $DataToJson(Data entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data["createdAt"] = entity.createdAt;
  data["banTime"] = entity.banTime;
  data["banType"] = entity.banType;
  data["isDevice"] = entity.isDevice;
  data["id"] = entity.id;
  data["deviceId"] = entity.deviceId;
  data["userId"] = entity.userId;
  data["banReason"] = entity.banReason;
  data["updatedAt"] = entity.updatedAt;
  return data;
}

Data $DataFromJson(Map<String, dynamic> jsonMap) {
  Data data = Data();
  int? createdAt = jsonConvert.convert<int>(jsonMap["createdAt"]);
  if (createdAt != null) {
    data.createdAt = createdAt;
  }
  int? banTime = jsonConvert.convert<int>(jsonMap["banTime"]);
  if (banTime != null) {
    data.banTime = banTime;
  }
  int? banType = jsonConvert.convert<int>(jsonMap["banType"]);
  if (banType != null) {
    data.banType = banType;
  }
  int? isDevice = jsonConvert.convert<int>(jsonMap["isDevice"]);
  if (isDevice != null) {
    data.isDevice = isDevice;
  }
  int? id = jsonConvert.convert<int>(jsonMap["id"]);
  if (id != null) {
    data.id = id;
  }
  String? deviceId = jsonConvert.convert<String>(jsonMap["deviceId"]);
  if (deviceId != null) {
    data.deviceId = deviceId;
  }
  int? userId = jsonConvert.convert<int>(jsonMap["userId"]);
  if (userId != null) {
    data.userId = userId;
  }
  String? banReason = jsonConvert.convert<String>(jsonMap["banReason"]);
  if (banReason != null) {
    data.banReason = banReason;
  }
  int? updatedAt = jsonConvert.convert<int>(jsonMap["updatedAt"]);
  if (updatedAt != null) {
    data.updatedAt = updatedAt;
  }
  return data;
}

