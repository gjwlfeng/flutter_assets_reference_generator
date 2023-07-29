import 'dart:async';
import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

class AssetsDirCommand extends Command<String> {
  @override
  String get description => "Generate the Assets dir class.";

  @override
  String get name => "assets_dir";

  @override
  FutureOr<String>? run() {
    String currentDir = Directory.current.path;

    File file = File("$currentDir/pubspec.yaml");
    bool isFileExists = file.existsSync();
    if (!isFileExists) {
      throw PathNotFoundException(file.path, OSError("Unable to find pubspec.yaml file!", 1));
    }

    Directory directory = Directory("$currentDir/lib");
    bool isLibDirExists = directory.existsSync();
    if (!isLibDirExists) {
      throw PathNotFoundException(directory.path, OSError("Unable to find lib folder!", 2));
    }

    String pubspecYamlContent = file.readAsStringSync();
    Pubspec pubspec = Pubspec.parse(pubspecYamlContent);

    Map<String, Directory> dirMap = {};
    if (pubspec.flutter != null) {
      YamlList fontsYamlList = pubspec.flutter!["assets"] ?? YamlList();
      for (String item in fontsYamlList) {
        String path = "$currentDir/$item";
        bool isFile = FileSystemEntity.isFileSync(path);
        if (isFile) {
          String parentPath = File(path).parent.path;
          if (dirMap[parentPath] == null) {
            dirMap[parentPath] = File(path).parent;
          }
        } else {
          bool isDir = FileSystemEntity.isDirectorySync(path);
          if (isDir) {
            Directory directory = Directory(path);
            if (dirMap[directory.path] == null) {
              dirMap[directory.path] = directory;
            }
          } else {
            print("Unable to identify whether the path is a file or a directory！$path");
          }
        }
      }
    }

    List<String> assetsKeyList = [];
    List<Field> fieldList = [];
    for (MapEntry<String, Directory> dirEntry in dirMap.entries) {
      var docsList = List.empty(growable: true);

      String shortPath = dirEntry.key.replaceAll("$currentDir/", "");

      String assetsDirWithDividerKey = shortPath.replaceAll(RegExp(r'\s'), "_").replaceAll("/", "_").replaceAll(".", "_");
      String assetsDirKey = assetsDirWithDividerKey.replaceFirst(RegExp(r'_'), "", assetsDirWithDividerKey.length - 1);

      docsList.add("///[$shortPath](${dirEntry.value.uri})");

      fieldList.add(Field((fieldBuild) => fieldBuild
        ..static = true
        ..name = assetsDirKey
        ..type = refer("String")
        ..modifier = FieldModifier.constant
        ..assignment = Code("\"$shortPath\"")
        ..docs = ListBuilder(docsList)));
    }

    final assetsDir = Class((classBuild) => classBuild //生成一个类
      ..name = "AssetsDir" //这个类的名字叫AssetsDir
      ..docs = ListBuilder(["///Code generation, please do not manually modify", "///Assets Dir Reference Class"])
      ..fields.addAll(fieldList));

    final emitter = DartEmitter();

    String assetsClassStr = DartFormatter().format('${assetsDir.accept(emitter)}');

    File assetsFile = File('$currentDir/lib/generated/assets_dir.dart');
    assetsFile.parent.createSync(recursive: true);
    assetsFile.writeAsStringSync(assetsClassStr);
    return null;
  }
}
