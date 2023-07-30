import 'dart:async';
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

class MapModelCommand extends Command<String> {
  @override
  String get description => "Processing method for generating JSON.";

  @override
  String get name => "map_model";

  bool isDebug = false;

  MapModelCommand() {
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

    try {
      var parseResult = parseFile(path: jsonfile.path, featureSet: FeatureSet.latestLanguageVersion());
      var compilationUnit = parseResult.unit;
      //遍历AST

      Map<String, dynamic>? map = compilationUnit.accept<Map<String, dynamic>>(ModelSimpleAstVisitor());

      List<Extension> extensionList = [];

      if (map != null) {
        printMap(map);

        List? classList = map["class"];

        classList?.forEach((element) {
          String className = element["name"];
          List? fieldList = element["fields"];

          List<Code> fromJsonCodeList = [];

          fromJsonCodeList.add(Code("$className ${className.initialLowercase()}=$className();"));

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
              //print(name);

              if (deserialize.toLowerCase() == 'true') {
                fromJsonCodeList.add(Code("$type $name=jsonConvert.convert<${type.replaceAll("?", "")}>(jsonMap[${annaKey ?? ("\"$name\"")}]);"));
                fromJsonCodeList.add(Code("if($name !=null ){ ${className.initialLowercase()}.$name=$name; }"));
              }
            });
          });

          fromJsonCodeList.add(Code("return ${className.initialLowercase()};"));

          Method fromJsonMethod = Method((MethodBuilder builder) {
            builder.name = "fromJson";
            builder.static = true;
            builder.requiredParameters.add(Parameter((ParameterBuilder builder) {
              builder.name = "jsonMap";
              builder.type = Reference("Map<String, dynamic>");
            }));
            builder.body = CodeBuilder.Block.of(fromJsonCodeList);
            builder.returns = Reference(className);
          });

          final extension = Extension((extensionBuilder) => extensionBuilder
            ..name = "${className}ModelExtension"
            ..on = refer(className)
            ..docs = ListBuilder(["///$className map extension"])
            ..methods = ListBuilder([fromJsonMethod]));
          extensionList.add(extension);
        });
      }

      final emitter = DartEmitter();

      File dartFile = File(join(jsonfile.parent.path, "${fileName}_model.dart"));

      if (!dartFile.parent.existsSync()) {
        dartFile.parent.createSync(recursive: true);
      }

      CodeBuilder.Directive mainDirective = CodeBuilder.Directive.import("$fileName.dart");
      String mainDirectiveStr = DartFormatter().format('${mainDirective.accept(emitter)}');

      dartFile.writeAsStringSync(mainDirectiveStr, mode: FileMode.write);
      dartFile.writeAsStringSync("\n", mode: FileMode.append);

      for (var extension in extensionList) {
        String extensionStr = DartFormatter().format('${extension.accept(emitter)}');
        dartFile.writeAsStringSync(extensionStr, mode: FileMode.append);
        dartFile.writeAsStringSync("\n", mode: FileMode.append);
      }
    } catch (e) {
      print('Parse file error: ${e.toString()}');
    }

    return null;
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
