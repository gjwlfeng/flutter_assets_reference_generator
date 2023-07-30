import 'person.dart';
import 'package:object_json_extension/object_json_extension.dart';

///Person json extension
extension PersonJsonExtension on Person {
  Map<String, dynamic> toJson(Person entity) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["code"] = entity.code.toJson();
    data["data"] = entity.data.toJson();
    data["messages"] = entity.messages.toJson();
    data["tag"] = entity.tag.toJson();
    data["timestamp"] = entity.timestamp.toJson();
    return data;
  }
}

///Data json extension
extension DataJsonExtension on Data {
  Map<String, dynamic> toJson(Data entity) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["createdAt"] = entity.createdAt.toJson();
    data["banTime"] = entity.banTime.toJson();
    data["banType"] = entity.banType.toJson();
    data["isDevice"] = entity.isDevice.toJson();
    data["id"] = entity.id.toJson();
    data["deviceId"] = entity.deviceId.toJson();
    data["userId"] = entity.userId.toJson();
    data["banReason"] = entity.banReason.toJson();
    data["updatedAt"] = entity.updatedAt.toJson();
    return data;
  }
}

