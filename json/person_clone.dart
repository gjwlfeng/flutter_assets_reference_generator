import 'person.dart';
import 'package:object_clone_extension/object_clone_extension.dart';

///Person clone extension
extension PersonCloneExtension on Person {
  Person clone(Person person) {
    Person entity = Person();
    entity.code = person.code.clone();
    entity.data = person.data.clone();
    entity.messages =
        person.messages?.map<String>((item) => item.clone()).toList();
    entity.tag =
        person.tag?.map((key, value) => MapEntry(key.clone(), value.clone()));
    entity.timestamp = person.timestamp.clone();
    return entity;
  }
}

///Data clone extension
extension DataCloneExtension on Data {
  Data clone(Data data) {
    Data entity = Data();
    entity.createdAt = data.createdAt.clone();
    entity.banTime = data.banTime.clone();
    entity.banType = data.banType.clone();
    entity.isDevice = data.isDevice.clone();
    entity.id = data.id.clone();
    entity.deviceId = data.deviceId.clone();
    entity.userId = data.userId.clone();
    entity.banReason = data.banReason.clone();
    entity.updatedAt = data.updatedAt.clone();
    return entity;
  }
}

