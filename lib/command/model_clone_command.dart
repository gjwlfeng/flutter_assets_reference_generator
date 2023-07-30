import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/code_builder.dart' as CodeBuilder;
import 'package:dart_style/dart_style.dart';
import 'package:flutter_assets_generate/extension.dart';
import 'package:path/path.dart';
import 'package:built_collection/built_collection.dart';
import 'package:args/command_runner.dart';

class ModelCloneCommand extends Command<String> {
  @override
  String get description => "Processing method for generating JSON.";

  @override
  String get name => "model_clone";

  bool isDebug = false;

  ModelCloneCommand() {
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
    String modelFilePath = argResults!["file"];

    File modelfile = File(modelFilePath);

    String fileName = basenameWithoutExtension(modelfile.path);

    if (isDebug) {
      print(modelfile.absolute.path);
    }

    if (!modelfile.existsSync()) {
      print("File not found (${modelfile.path});");
      return null;
    }

    try {
      var parseResult = parseFile(path: modelfile.path, featureSet: FeatureSet.latestLanguageVersion());
      var compilationUnit = parseResult.unit;
      //遍历AST

      Map<String, dynamic>? map = compilationUnit.accept<Map<String, dynamic>>(ModelSimpleAstVisitor());

      List<Extension> extensionList = [];

      if (map != null) {
        if (isDebug) {
          print(jsonEncode(map));
        }

        List? classList = map["class"];

        classList?.forEach((element) {
          String className = element["name"];
          List? fieldList = element["fields"];

          List<Code> cloneCodeList = [];

          String newModelName = "entity";

          cloneCodeList.add(Code("$className $newModelName=$className();"));

          fieldList?.forEach((field) {
            List? items = field["items"];
            Map? metadata = field["metadata"];

            List? annaKeyValueList = metadata?["JSONField"];

            String? annaKey;

            String serialize = 'true';

            String deserialize = "true";

            annaKeyValueList?.forEach((element) {
              if (element["key"] == "name") {
                annaKey = element["value"];
              } else if (element["key"] == "serialize") {
                serialize = element["value"];
              } else if (element["key"] == "deserialize") {
                deserialize = element["value"];
              }
            });

            items?.forEach((item) {
              String name = item["name"];
              String type = item["type"];

              //  entity.messages= person.messages?.map<String>((item) => item.clone()).toList();
              //   entity.tag= person.tag?.map((key, value) =>
              //       MapEntry(key.clone(),value.clone())
              //   );

              if (type.startsWith("List<")) {
                int startIndex = type.indexOf("<");
                int endIndex = type.indexOf(">");
                String genericity = type.substring(startIndex + 1, endIndex);
                cloneCodeList.add(Code("$newModelName.$name=${className.initialLowercase()}.$name?.map<$genericity>((item)=> item.clone()).toList();"));
              } else if (type.startsWith("Map<")) {
                int startIndex = type.indexOf("<");
                int endIndex = type.indexOf(">");
                String genericity = type.substring(startIndex + 1, endIndex);
                cloneCodeList.add(Code("$newModelName.$name=${className.initialLowercase()}.$name?.map((key, value)=> MapEntry(key.clone(),value.clone()));"));
              } else {
                cloneCodeList.add(Code("$newModelName.$name=${className.initialLowercase()}.$name.clone();"));
              }
            });
          });
          cloneCodeList.add(Code("return $newModelName;"));

          Method cloneMethod = Method((MethodBuilder builder) {
            builder.name = "clone";
            builder.requiredParameters.add(Parameter((ParameterBuilder builder) {
              builder.name = className.initialLowercase();
              builder.type = Reference(className);
            }));
            builder.body = CodeBuilder.Block.of(cloneCodeList);
            builder.returns = Reference(className);
          });

          final extension = Extension((extensionBuilder) => extensionBuilder
            ..name = "${className}CloneExtension"
            ..on = refer(className)
            ..docs = ListBuilder(["///$className clone extension"])
            ..methods = ListBuilder([cloneMethod]));
          extensionList.add(extension);
        });
      }

      final emitter = DartEmitter();

      File dartFile = File(join(modelfile.parent.path, "${fileName}_clone.dart"));

      if (!dartFile.parent.existsSync()) {
        dartFile.parent.createSync(recursive: true);
      }

      DartFormatter dartFormatter = DartFormatter();

      CodeBuilder.Directive pathDirective = CodeBuilder.Directive.import("$fileName.dart");
      CodeBuilder.Directive objectCloneDirective = CodeBuilder.Directive.import("package:object_clone_extension/object_clone_extension.dart");

      String pathDirectiveStr = dartFormatter.format('${pathDirective.accept(emitter)}');
      String objectCloneDirectiveStr = dartFormatter.format('${objectCloneDirective.accept(emitter)}');

      if (isDebug) {
        print(pathDirective.toString());
        print(objectCloneDirective.toString());
      }

      dartFile.writeAsStringSync(pathDirectiveStr);
      dartFile.writeAsStringSync(objectCloneDirectiveStr, mode: FileMode.append);
      dartFile.writeAsStringSync("\n", mode: FileMode.append);
      for (var extension in extensionList) {
        if (isDebug) {
          print(extension.toString());
        }
        String extensionStr = dartFormatter.format('${extension.accept(emitter)}');
        dartFile.writeAsStringSync(extensionStr, mode: FileMode.append);
        dartFile.writeAsStringSync("\n", mode: FileMode.append);
      }
    } catch (e) {
      print('Parse file error: ${e.toString()}');
    }

    return null;
  }

  void codeBlack(List<Code> cloneCodeList, Function(List<Code> cloneCodeList) callback, {String? condition}) {
    cloneCodeList.add(Code(condition != null ? "$condition{" : "{"));
    callback(cloneCodeList);
    cloneCodeList.add(Code("}"));
  }

  void printMap(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (value is Map) {
        print(key);
        printMap(value as Map<String, dynamic>);
      } else {
        print('$key=$value');
      }
    });
  }
}

class ModelSimpleAstVisitor extends GeneralizingAstVisitor<Map<String, dynamic>> {
  /// 遍历节点
  Map<String, dynamic>? _safelyVisitNode(AstNode node) {
    return node.accept(this);
  }

  /// 遍历节点列表
  List<Map> _safelyVisitNodeList(NodeList<AstNode>? nodes) {
    List<Map> maps = [];
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        var node = nodes[i];
        var res = node.accept(this);
        if (res != null) {
          maps.add(res);
        }
      }
    }
    return maps;
  }

  //构造根节点
  Map<String, dynamic>? _buildAstRoot(List<Map> body) {
    if (body.isNotEmpty) {
      return {
        "type": "Program",
        "body": body,
      };
    } else {
      return null;
    }
  }

  //构造根节点
  Map<String, dynamic>? _buildAstClass(List<Map> directiveList, List<Map> clzList) {
    return {"type": "Program", "directives": directiveList, "class": clzList};
  }

  //directives节点
  Map<String, dynamic>? _buildAstDirectives(List<Map> directiveList) {
    if (directiveList.isNotEmpty) {
      return {
        "type": "Directive",
        "directive": directiveList,
      };
    } else {
      return null;
    }
  }

  @override
  Map<String, dynamic>? visitCompilationUnit(CompilationUnit node) {
    return _buildAstClass(_safelyVisitNodeList(node.directives), _safelyVisitNodeList(node.declarations));
  }

  @override
  Map<String, dynamic>? visitPartDirective(PartDirective node) {
    Map<String, dynamic> map = {};
    map["part"] = node.uri;
    return map;
  }

  @override
  Map<String, dynamic>? visitClassDeclaration(ClassDeclaration node) {
    Map<String, dynamic> map = {};
    map["name"] = node.name.toString();
    map["fields"] = _safelyVisitNodeList(node.members);
    return map;
  }

  @override
  Map<String, dynamic>? visitFieldDeclaration(FieldDeclaration node) {
    Map<String, dynamic> map = {};

    Map metadatas = {};

    List fields = [];

    for (var element in node.metadata) {
      String annaName = element.name.name;

      List items = [];
      // ignore: avoid_function_literals_in_foreach_calls
      element.arguments?.arguments.forEach((args) {
        if (args is NamedExpression) {
          items.add({
            "key": args.name.label.toSource(),
            "value": args.expression.toSource(),
          });
        }
      });
      metadatas[annaName] = items;
    }

    for (var element in node.fields.variables) {
      fields.add({"name": element.name.toString(), "type": node.fields.type?.toSource()});
    }
    map["metadata"] = metadatas;
    map["items"] = fields;
    return map;
  }
}
