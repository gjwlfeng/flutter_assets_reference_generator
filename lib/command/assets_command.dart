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
  FutureOr<String>? run() async {
    String currentDir = Directory.current.path;

    File file = File("$currentDir/pubspec.yaml");
    bool isFileExists = file.existsSync();
    if (!isFileExists) {
      throw PathNotFoundException(
          file.path, OSError("Unable to find pubspec.yaml file!", 1));
    }

    Directory directory = Directory("$currentDir/lib");
    bool isLibDirExists = directory.existsSync();
    if (!isLibDirExists) {
      throw PathNotFoundException(
          directory.path, OSError("Unable to find lib folder!", 2));
    }

    String pubspecYamlContent = file.readAsStringSync();
    Pubspec pubspec = Pubspec.parse(pubspecYamlContent);

    List<File> fileList = [];
    if (pubspec.flutter != null) {
      YamlList fontsYamlList = pubspec.flutter!["assets"] ?? YamlList();
      for (String item in fontsYamlList) {
        String path = "${currentDir}/${item}";
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
            print(
                "Unable to identify whether the path is a file or a directory！${path}");
          }
        }
      }
    }

    List<String> assetsKeyList = [];
    List<Field> fieldList = [];
    for (File file in fileList) {
      var docsList = List.empty(growable: true);

      String extension = path.extension(file.path);
      String shortPath = file.path.replaceAll("${currentDir}/", "");
      String assetsKey = shortPath.replaceAll(extension, "");

      if (assetsKeyList.contains(assetsKey)) {
        throw Exception("Duplicate ${shortPath}");
      }

      assetsKeyList.add(assetsKey);
      docsList.add("///${shortPath}");

      try {
        var fileList = await file.readAsBytes();
        var decoder = ddImage.decodeImage(Uint8List.fromList(fileList));
        bool isValid = decoder?.isValid ?? false;
        if (isValid) {
          docsList.add("///size:${decoder!.width}x${decoder.height}");
        }
      } catch (e) {
        stderr.writeln(e.toString());
      }

      fieldList.add(Field((fieldBuild) => fieldBuild
        ..static = true
        ..name = assetsKey
            .replaceAll(RegExp(r'\s'), "_")
            .replaceAll("/", "_")
            .replaceAll(".", "_")
        ..type = refer("String")
        ..modifier = FieldModifier.constant
        ..assignment = Code("\"${shortPath}\"")
        ..docs = ListBuilder(docsList)));
    }

    final assets = Class((classBuild) => classBuild //生成一个类
      ..name = "Assets" //这个类的名字叫User
      ..docs = ListBuilder([
        "///Code generation, please do not manually modify",
        "///Assets Reference Class"
      ])
      ..fields.addAll(fieldList));

    final emitter = DartEmitter();
    String assetsClassStr = DartFormatter().format('${assets.accept(emitter)}');

    File assetsFile = File('$currentDir/lib/generated/assets.dart');
    assetsFile.parent.createSync(recursive: true);
    assetsFile.writeAsStringSync(assetsClassStr);
    return Future.value("");
  }
}
