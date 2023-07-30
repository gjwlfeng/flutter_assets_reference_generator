import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:code_builder/code_builder.dart' as CodeBuilder;
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_assets_generate/extension.dart';

import 'package:path/path.dart';
import 'package:args/command_runner.dart';

class JsonModelCommand extends Command<String> {
  @override
  String get description => "Generate model classes based on JSON.";

  @override
  String get name => "json_model";

  bool isDebug = false;

  JsonModelCommand() {
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

    List<CodeBuilder.Class> clzList = [];

    if (json is Map) {
      generateClassFromMap(clzList, json as Map<String, dynamic>, fileName.capitalize());
    } else if (json is List) {
      List<String> genericityList = [];
      getGenerateClassFromList(clzList, genericityList, json, fileName.capitalize());
    } else {
      print("Unprocessable type(${json.runtimeType})");
      return null;
    }

    File dartFile = File(join(jsonfile.parent.path, "$fileName.dart"));

    final emitter = DartEmitter();

    CodeBuilder.Directive partDirective = CodeBuilder.Directive.part("$fileName.g.dart");
    String partDirectiveStr = DartFormatter().format('${partDirective.accept(emitter)}');

    dartFile.writeAsStringSync(partDirectiveStr, mode: FileMode.write);
    dartFile.writeAsStringSync("\n", mode: FileMode.append);

    for (var value in clzList.reversed) {
      String classStr = DartFormatter().format('${value.accept(emitter)}');
      dartFile.writeAsStringSync(classStr, mode: FileMode.append);
      dartFile.writeAsStringSync("\n", mode: FileMode.append);
    }
    return null;
  }

  String generateClassFromMap(List<CodeBuilder.Class> clzList, Map<String, dynamic> jsonMap, String className) {
    List<CodeBuilder.Field> fieldList = [];

    if (isDebug) {
      print("-----------$className-------------");
    }

    for (var element in jsonMap.entries) {
      print("${element.key}=${element.value}=${element.value.runtimeType}\n");

      CodeBuilder.Reference fieldTypeRef = CodeBuilder.Reference("dynamic?");

      if (element.value is int) {
        fieldTypeRef = CodeBuilder.Reference("int?");
      } else if (element.value is String) {
        fieldTypeRef = CodeBuilder.Reference("String?");
      } else if (element.value is double) {
        fieldTypeRef = CodeBuilder.Reference("double?");
      } else if (element.value is bool) {
        fieldTypeRef = CodeBuilder.Reference("bool?");
      } else if (element.value is List) {
        List<String> genericityList = [];
        List<dynamic> list = (element.value as List);
        getGenerateClassFromList(clzList, genericityList, list, element.key.capitalize());
        String genericitys = getListGenericitys(genericityList);
        fieldTypeRef = CodeBuilder.Reference("$genericitys?");
      } else if (element.value is Map) {
        String childCallName = element.key.capitalize();
        generateClassFromMap(clzList, element.value, childCallName);
        fieldTypeRef = CodeBuilder.Reference("${element.key.capitalize()}?");
      } else {
        print("Unprocessable type( ${element.key}=${json.runtimeType})");
      }

      if (isDebug) {
        print("${element.key}=${element.value.runtimeType}");
      }

      fieldList.add(CodeBuilder.Field((CodeBuilder.FieldBuilder fieldBuilder) {
        fieldBuilder.name = element.key;
        fieldBuilder.type = fieldTypeRef;
      }));
    }

    final clz = CodeBuilder.Class((classBuild) => classBuild
      ..name = className
      ..fields.addAll(fieldList)
      ..methods.add(Method((MethodBuilder builder) {
        builder.name = className;
      }))
      ..constructors.add(CodeBuilder.Constructor((CodeBuilder.ConstructorBuilder builder) {
        builder.factory = true;
        builder.name = "copy";
        builder.requiredParameters.add(CodeBuilder.Parameter((CodeBuilder.ParameterBuilder builder) {
          builder.name = "entity";
          builder.type = CodeBuilder.Reference(className);
        }));
        builder.lambda = true;
        builder.body = builder.body = CodeBuilder.Code('\$${className}Copy(entity)');
      }))
      ..constructors.add(CodeBuilder.Constructor((CodeBuilder.ConstructorBuilder builder) {
        builder.factory = true;
        builder.name = "fromJson";
        builder.requiredParameters.add(CodeBuilder.Parameter((CodeBuilder.ParameterBuilder builder) {
          builder.name = "jsonMap";
          builder.type = CodeBuilder.Reference("Map<String, dynamic>");
        }));
        builder.lambda = true;

        builder.body = builder.body = CodeBuilder.Code('\$${className}FromJson(jsonMap)');
      }))
      ..methods.add(CodeBuilder.Method((CodeBuilder.MethodBuilder builder) {
        builder.name = "toJson";
        builder.body = CodeBuilder.Code('\$${className}ToJson(this)');
        builder.returns = CodeBuilder.Reference("Map<String,dynamic>");
        builder.lambda = true;
      })));

    clzList.add(clz);

    return className;
  }

  void getGenerateClassFromList(List<CodeBuilder.Class> clzList, List<String> genericityList, List<dynamic> jsonList, String className) {
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
        getGenerateClassFromList(clzList, genericityList, element, className);
      } else if (element is Map) {
        String childCallName = className;
        String type = generateClassFromMap(clzList, element as Map<String, dynamic>, childCallName);
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
    }
    return listGenericity;
  }
}
