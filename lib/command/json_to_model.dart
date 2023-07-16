import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_assets_generate/%20extension.dart';
import 'package:path/path.dart';
import 'package:args/command_runner.dart';

class JsonToModelCommand extends Command<String> {
  @override
  String get description => "Generate model classes based on JSON.";

  @override
  String get name => "jsonToModel";

  bool isDebug = false;

  JsonToModelCommand() {
    argParser.addOption('file', abbr: 'f');
    argParser.addFlag("debug", defaultsTo: false);
  }

  @override
  FutureOr<String>? run() {
    String currentDir = Directory.current.path;

    if (argResults == null) {
      print("Parsing command failed");
      return null;
    }
    isDebug = argResults!["debug"];
    String jsonFilePath = argResults!["file"];

    File jsonfile = File(jsonFilePath);

    String fileName = basenameWithoutExtension(jsonfile.path);

    if (isDebug) {
      print(jsonfile.absolute.path);
    }

    if (!jsonfile.existsSync()) {
      print("File not found (${jsonfile.path});");
      return null;
    }

    String jsonStr = jsonfile.readAsStringSync();

    dynamic json = jsonDecode(jsonStr);

    LinkedHashMap<String, Class> clzMap = LinkedHashMap();

    if (json is Map) {
      generateClassFromMap(clzMap, json as Map<String, dynamic>, fileName.capitalize());
    } else if (json is List) {
      List<String> genericityList = [];
      getGenerateClassFromList(clzMap, genericityList, json, fileName.capitalize());
    } else {
      print("Unprocessable type(${json.runtimeType})");
      return null;
    }

    File dartFile = File(join(jsonfile.parent.path, "$fileName.dart"));

    final emitter = DartEmitter();

    dartFile.writeAsStringSync("", mode: FileMode.write);

    clzMap.forEach((key, value) {
      String classStr = DartFormatter().format('${value.accept(emitter)}');
      dartFile.writeAsStringSync(classStr, mode: FileMode.append);
      dartFile.writeAsStringSync("\n", mode: FileMode.append);
    });

    return null;
  }

  String generateClassFromMap(LinkedHashMap<String, Class> clzMap, Map<String, dynamic> jsonMap, String className) {
    List<Field> fieldList = [];

    if (isDebug) {
      print("-----------$className-------------");
    }

    for (var element in jsonMap.entries) {
      print("${element.key}=${element.value}=${element.value.runtimeType}\n");

      Reference fieldTypeRef = Reference("dynamic?");

      if (element.value is int) {
        fieldTypeRef = Reference("int?");
      } else if (element.value is String) {
        fieldTypeRef = Reference("String?");
      } else if (element.value is double) {
        fieldTypeRef = Reference("double?");
      } else if (element.value is bool) {
        fieldTypeRef = Reference("bool?");
      } else if (element.value is List) {
        List<String> genericityList = [];
        List<dynamic> list = (element.value as List);
        getGenerateClassFromList(clzMap, genericityList, list, element.key.capitalize());
        String genericitys = getListGenericitys(genericityList);
        fieldTypeRef = Reference("$genericitys?");
      } else if (element.value is Map) {
        String childCallName = element.key.capitalize();
        generateClassFromMap(clzMap, element.value, childCallName);
        fieldTypeRef = Reference("${element.key.capitalize()}?");
      } else {
        print("Unprocessable type( ${element.key}=${json.runtimeType})");
      }

      if (isDebug) {
        print("${element.key}=${element.value.runtimeType}");
      }

      fieldList.add(Field((FieldBuilder fieldBuilder) {
        fieldBuilder.name = element.key;
        fieldBuilder.type = fieldTypeRef;
      }));
    }

    final clz = Class((classBuild) => classBuild
      ..name = className
      ..fields.addAll(fieldList));

    clzMap[clz.name] = clz;

    return className;
  }

  void getGenerateClassFromList(LinkedHashMap<String, Class> clzMap, List<String> genericityList, List<dynamic> jsonList, String className) {
    for (var element in jsonList) {
      print("$element=${element.runtimeType}\n");

      if (element is int) {
        genericityList.add("int");
      } else if (element is String) {
        genericityList.add("String");
      } else if (element is double) {
        genericityList.add("double");
      } else if (element is List) {
        genericityList.add("List");
        getGenerateClassFromList(clzMap, genericityList, element, className);
      } else if (element is Map) {
        String childCallName = className;
        String type = generateClassFromMap(clzMap, element as Map<String, dynamic>, childCallName);
        genericityList.add(type);
      } else if (element.value is bool) {
        genericityList.add("bool");
      }
      break;
    }
  }

  String getListGenericity(String type) {
    return "List<$type>";
  }

  String getListGenericitys(List<String> genericityList) {
    print(genericityList);
    if (genericityList.length >= 2) {
      return _listGenericitys(genericityList.last, genericityList.sublist(0, genericityList.length - 1));
    } else if (genericityList.length == 1) {
      return getListGenericity(genericityList.first);
    } else {
      return getListGenericity("dynamic");
    }
  }

  String _listGenericitys(String listGenericity, List<String> genericityList) {
    for (var element in genericityList.reversed) {
      listGenericity = "$element<$listGenericity>";

      print(listGenericity);
    }

    return listGenericity;
  }
}
