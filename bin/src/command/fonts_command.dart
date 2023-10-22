import 'dart:async';
import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

class FontsCommand extends Command<String> {
  @override
  String get description => "Generate the Fonts class.";

  @override
  String get name => "fonts";

  @override
  FutureOr<String>? run() {
    String currentDir = Directory.current.path;

    File file = File("$currentDir/pubspec.yaml");
    bool isFileExists = file.existsSync();
    if (!isFileExists) {
      stderr.writeln("Unable to find pubspec.yaml file!");
      return null;
    }

    Directory directory = Directory("$currentDir/lib");
    bool isLibDirExists = directory.existsSync();
    if (!isLibDirExists) {
      directory.createSync(recursive: true);
    }

    String pubspecYamlContent = file.readAsStringSync();
    Pubspec pubspec = Pubspec.parse(pubspecYamlContent);

    List<Field> fieldList = [];

    if (pubspec.flutter != null) {
      YamlList fontsYamlList = pubspec.flutter!["fonts"] ?? YamlList();
      for (var fontsItem in fontsYamlList) {
        if (fontsItem is! YamlMap) {
          continue;
        }

        String familyName = fontsItem["family"];
        fieldList.add(Field((fieldBuild) => fieldBuild
          ..static = true
          ..name = familyName.replaceAll(RegExp(r'\s'), "_")
          ..type = refer("String") //变量类型为String
          ..modifier = FieldModifier.constant
          ..assignment = Code("\"$familyName\"")));
      }
    }

    final buildConfig = Class((classBuild) => classBuild
      ..name = "Fonts"
      ..docs = ListBuilder(["///Code generation, please do not manually modify", "///Font Name Reference Class"])
      ..fields.addAll(fieldList));

    final emitter = DartEmitter();
    String fontsClassStr = DartFormatter().format('${buildConfig.accept(emitter)}');

    File fontsFile = File('$currentDir/lib/generated/fonts.dart');
    fontsFile.parent.createSync(recursive: true);
    fontsFile.writeAsStringSync(fontsClassStr);
    return null;
  }
}
