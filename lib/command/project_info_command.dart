import 'dart:async';
import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:code_builder/code_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class BuildConfigCommand extends Command<String> {
  @override
  String get description => "Generate the ProjectInfo class.";

  @override
  String get name => "projectInfo";

  @override
  List<String> get aliases => ['info'];

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

    final buildConfig = Class(
      (classBuild) => classBuild
        ..name = "ProjectInfo"
        ..docs = ListBuilder(["///Code generation, please do not manually modify", "///project info Reference Class"])
        ..fields.add(
          Field(
            (fieldBuild) => fieldBuild
              ..static = true
              ..name = "name"
              ..type = refer("String")
              ..modifier = FieldModifier.constant
              ..assignment = Code("\"${pubspec.name}\"")
              ..docs = ListBuilder<String>(["///ProjectName"]),
          ),
        )
        ..fields.add(
          Field(
            (fieldBuild) => fieldBuild
              ..static = true
              ..name = "version"
              ..type = refer("String")
              ..modifier = FieldModifier.constant
              ..assignment = Code("\"${pubspec.version}\"")
              ..docs = ListBuilder<String>(["///versionName"]),
          ),
        ),
    );

    final emitter = DartEmitter();
    String buildConfigClassStr = DartFormatter().format('${buildConfig.accept(emitter)}');

    File buildConfigFile = File('$currentDir/lib/generated/project_info.dart');
    buildConfigFile.parent.createSync(recursive: true);
    buildConfigFile.writeAsStringSync(buildConfigClassStr);
    return null;
  }
}
