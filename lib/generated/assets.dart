import 'package:path/path.dart' as path;

///Code generation, please do not manually modify
///Assets Reference Class
class Assets {}

///Assets extension
extension AssetsExtension on String {
  String get fileName {
    return path.basename(this);
  }
}
