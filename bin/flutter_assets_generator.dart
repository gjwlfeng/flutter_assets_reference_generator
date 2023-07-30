import 'package:args/command_runner.dart';
import 'package:flutter_assets_generate/command/assets_dir_command.dart';
import 'package:flutter_assets_generate/command/json_model_command.dart';
import 'package:flutter_assets_generate/command/map_model_command.dart';
import 'package:flutter_assets_generate/command/model_clone_command.dart';
import 'package:flutter_assets_generate/command/model_json_command.dart';
import 'package:flutter_assets_generate/command/project_info_command.dart';
import 'package:flutter_assets_generate/command/fonts_command.dart';
import 'package:flutter_assets_generate/command/assets_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<String>('fag', 'Flutter resource reference generation tool!')
    ..addCommand(AssetsCommand())
    ..addCommand(AssetsDirCommand())
    ..addCommand(FontsCommand())
    ..addCommand(BuildConfigCommand())
    ..addCommand(JsonModelCommand())
    ..addCommand(MapModelCommand())
    ..addCommand(ModelJsonCommand())
    ..addCommand(ModelCloneCommand());
  await runner.run(arguments);
}
