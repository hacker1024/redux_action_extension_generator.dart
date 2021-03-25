import 'package:build/build.dart';
import 'package:redux_action_extension_generator/src/action_extension_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder reduxActionExtensionBuilder(BuilderOptions options) {
  T _getOption<T>(String key) {
    final value = options.config[key];
    if (value is! T) {
      throw ArgumentError(
          'The option "$key" requires a value of type "$T" (not "${value.runtimeType}")!');
    }
    return value;
  }

  final stateType = _getOption<String?>('state_type');
  var stateImportPath = _getOption<String?>('state_import_path');

  if (stateImportPath == null) {
    if (stateType != null) {
      throw ArgumentError(
          'The state type is provided, so the state import path is required!');
    }
  } else {
    if (stateType == null) {
      print(
          'The state import path is provided, but no state type is given. The import path will not be used.');
      stateImportPath = null;
    }
  }

  if (stateType != null && stateImportPath == null) {
    throw ArgumentError(
        'The state type is provided, so the state import path is required!');
  }

  return LibraryBuilder(
    ActionExtensionGenerator(
      stateType: stateType,
      stateImportPath: stateImportPath,
      removeActionPrefix: _getOption('remove_action_prefix'),
      removeActionSuffix: _getOption('remove_action_suffix'),
    ),
    generatedExtension: '.action_extensions.dart',
  );
}
