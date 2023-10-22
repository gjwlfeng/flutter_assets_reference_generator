import 'package:args/command_runner.dart';
import 'src/command//assets_dir_command.dart';
import 'src/command/project_info_command.dart';
import 'src/command/fonts_command.dart';
import 'src/command/assets_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<String>('fag', 'Flutter Resource Reference Class Generation Tool!')
    ..addCommand(AssetsCommand())
    ..addCommand(AssetsDirCommand())
    ..addCommand(FontsCommand())
    ..addCommand(BuildConfigCommand());
  await runner.run(arguments);
}
