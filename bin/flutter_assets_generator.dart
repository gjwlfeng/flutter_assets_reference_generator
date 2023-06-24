import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_assets_generate/command/project_info_command.dart';
import 'package:flutter_assets_generate/command/fonts_command.dart';
import 'package:flutter_assets_generate/command/assets_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<String>('fag', 'Flutter resource reference generation tool!')
    ..addCommand(AssetsCommand())
    ..addCommand(FontsCommand())
    ..addCommand(BuildConfigCommand());
   await runner.run(arguments);

}
