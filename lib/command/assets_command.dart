import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:built_collection/built_collection.dart';
import 'package:args/command_runner.dart';
import 'package:image/image.dart' as ddImage;
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

class AssetsCommand extends Command<String> {
  @override
  String get description => "Generate the Assets class.";

  @override
  String get name => "assets";

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

    List<File> fileList = [];
    if (pubspec.flutter != null) {
      YamlList fontsYamlList = pubspec.flutter!["assets"] ?? YamlList();
      for (String item in fontsYamlList) {
        String path = "$currentDir/$item";
        bool isFile = FileSystemEntity.isFileSync(path);
        if (isFile) {
          fileList.add(File(path));
        } else {
          bool isDir = FileSystemEntity.isDirectorySync(path);
          if (isDir) {
            Directory directory = Directory(path);
            List<FileSystemEntity> files = directory.listSync();
            for (FileSystemEntity file in files) {
              if (file is File) {
                fileList.add(file);
              }
            }
          } else {
            print("Unable to identify whether the path is a file or a directory！$path");
          }
        }
      }
    }

    List<String> assetsKeyList = [];
    List<Field> fieldList = [];
    for (File file in fileList) {
      String extension = path.extension(file.path);
      String shortPath = file.path.replaceAll("$currentDir/", "");
      String assetsKey = shortPath.replaceAll(extension, "");

      if (assetsKeyList.contains(assetsKey)) {
        throw Exception("Duplicate $shortPath");
      }

      assetsKeyList.add(assetsKey);

      var docsList = List.empty(growable: true);
      var docsList2 = List.empty(growable: true);

      docsList.add("///[$shortPath](${file.uri})");

      try {
        var imageFile = file.readAsBytesSync();
        var decoder = ddImage.decodeImage(Uint8List.fromList(imageFile));
        bool isValid = decoder?.isValid ?? false;
        if (isValid) {
          docsList2.add("///```json");
          docsList2.add("///{");
          docsList2.add("///  \"x4\":{\"withd\":${decoder!.width / 4},\"height\":${decoder.height / 4},},");
          docsList2.add("///  \"x3\":{\"withd\":${decoder.width / 3},\"height\":${decoder.height / 3},},");
          docsList2.add("///  \"x2\":{\"withd\":${decoder.width / 2},\"height\":${decoder.height / 2},},");
          docsList2.add("///  \"x1\":{\"withd\":${decoder.width / 1},\"height\":${decoder.height / 1},},");
          docsList2.add("///}");
          docsList2.add("///```");
        }
      } catch (e) {
        stderr.writeln("$e");
        stderr.writeln("Failed to obtain image size! ${file.path}");
      }
      if (docsList2.isNotEmpty) {
        docsList.addAll(docsList2);
      }

      fieldList.add(Field((fieldBuild) => fieldBuild
        ..static = true
        ..name = assetsKey.replaceAll(RegExp(r'\s'), "_").replaceAll("/", "_").replaceAll(".", "_")
        ..type = refer("String")
        ..modifier = FieldModifier.constant
        ..assignment = Code("\"$shortPath\"")
        ..docs = ListBuilder(docsList)));
    }

    final assets = Class((classBuild) => classBuild //生成一个类
      ..name = "Assets" //这个类的名字叫Assets
      ..docs = ListBuilder(["///Code generation, please do not manually modify", "///Assets Reference Class"])
      ..fields.addAll(fieldList));

    Method fineNameMethod = Method((methodBuilder) => methodBuilder
      ..name = "fileName"
      ..type = MethodType.getter
      ..returns = refer("String")
      ..body = Code('''
              return path.basename(this);
        '''));

    final stringExtension = Extension((extensionBuilder) => extensionBuilder
      ..name = "AssetsExtension"
      ..on = refer("String")
      ..docs = ListBuilder(["///Assets extension"])
      ..methods = ListBuilder([fineNameMethod]));

    Directive pathDirective = Directive.import("package:path/path.dart", as: "path");

    final emitter = DartEmitter();
    String pathDirectiveStr = DartFormatter().format('${pathDirective.accept(emitter)}');
    String assetsClassStr = DartFormatter().format('${assets.accept(emitter)}');
    String stringExtensionClassStr = DartFormatter().format('${stringExtension.accept(emitter)}');

    File assetsFile = File('$currentDir/lib/generated/assets.dart');
    assetsFile.parent.createSync(recursive: true);

    assetsFile.writeAsStringSync(pathDirectiveStr);
    assetsFile.writeAsStringSync("\n", mode: FileMode.append);
    assetsFile.writeAsStringSync(assetsClassStr, mode: FileMode.append);
    assetsFile.writeAsStringSync("\n", mode: FileMode.append);
    assetsFile.writeAsStringSync(stringExtensionClassStr, mode: FileMode.append);
    return null;
  }
}
