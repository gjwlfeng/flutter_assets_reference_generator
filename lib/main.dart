import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  File file = File("/Users/zengfeng/Documents/WorkSpace/Flutter/flutter_assets_generate/json/Person.json");
  String jsonStr = file.readAsStringSync();
  dynamic dd = jsonDecode(jsonStr);
  if (dd is Map) {
    for (var element in dd.entries) {
      if (element.value is Map) {
        print("${element.key}=${element.value}=${element.value.runtimeType}\n");
      } else {
        print("${element.value.runtimeType}\n");
      }
    }
  }
}
