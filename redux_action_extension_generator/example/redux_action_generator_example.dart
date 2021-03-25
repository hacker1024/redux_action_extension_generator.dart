import 'package:redux_action_extension_annotation/redux_action_extension_annotation.dart';

class ExampleAction {
  final String exampleValue;

  @ActionExtension()
  const ExampleAction(this.exampleValue);

  @ActionExtension()
  const ExampleAction.defaultValue() : this('default');
}

// Example generated code:
/*
import 'package:redux/redux.dart' show Store;
import 'package:example_package/src/redux/actions/example_file.dart';

extension ExampleFileActionExtensions on Store {
  void example(String exampleValue) => dispatch(ExampleAction(exampleValue));
  void exampleDefaultValue() => dispatch(const ExampleAction.defaultValue());
}
 */
