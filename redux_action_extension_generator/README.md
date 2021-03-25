# Redux Action Extension Generator
A Dart-style equivalent to JavaScript Redux's [action creator concept].

This package uses code generation to generate extension methods on
[`package:redux`][package:redux]'s [`Store`][package:redux Store].

The extension methods correspond to action constructors, and construct and
dispatch actions when called.

[action creator concept]: https://redux.js.org/recipes/reducing-boilerplate#action-creators
[package:redux]: https://pub.dev/packages/redux
[package:redux Store]: https://pub.dev/documentation/redux/latest/redux/Store-class.html

## Usage
Add the following to your `pubspec.yaml`:
```yaml
dependencies:
  redux_action_extension_annotation: ^0.1.0

dev_dependencies:
  build_runner: <a build_runner version>
  redux_action_extension_generator:
    git:
      url: 'git://github.com/hacker1024/redux_action_extension_generator.dart.git'
      path: 'redux_action_extension_generator'
      ref: '<the latest commit hash>'

dependency_overrides:
  redux_action_extension_annotation:
    git:
      url: 'git://github.com/hacker1024/redux_action_extension_generator.dart.git'
      path: 'redux_action_extension_annotation'
      ref: '<the latest commit hash>'
```

### Quick start
To generate extension methods, annotate action constructors with the
`ActionExtension` annotation:

`./lib/src/redux/actions/example_file.dart`
```dart
import 'package:redux_action_extension_annotation/redux_action_extension_annotation.dart';

class ExampleAction {
  final String exampleValue;
  
  @ActionExtension()
  const ExampleAction(this.exampleValue);

  @ActionExtension()
  const ExampleAction.defaultValue() : this('default');
}
```

This code will generate the following extension:

`./lib/src/redux/actions/example_file.action_extensions.dart`
```dart
import 'package:redux/redux.dart' show Store;
import 'package:example_package/src/redux/actions/example_file.dart';

extension ExampleFileActionExtensions on Store {
  void exampleAction(String exampleValue) => dispatch(ExampleAction(exampleValue));
  void exampleActionDefaultValue() => dispatch(const ExampleAction.defaultValue());
}
```

[`package:build_runner`][package:build_runner] can be used to execute builds.

[package:build_runner]: https://pub.dev/packages/build_runner

### Advanced usage
#### Method name configuration
Extension methods can have custom names. Use the annotation's `name` parameter for this:
```dart
@ActionExtension(name: 'customName')
```
#### Generator configuration
The generator can be configured through `build.yaml`.
See [`package:build_config`][package:build_config] for more information.

|**Option**|**Type**|**Default**|**Description**|
|----------|--------|-----------|---------------|
|`state_type`|String| |If set, extensions will apply to `Store<state_type>` instead of `Store<dynamic>`.|
|`state_import_path`|String| |The import URI of the library containing the `state_type`. This must be set if `state_type` is set.|
|`remove_action_prefix`|Boolean|`false`|Removes "Action" prefixes from generated method names.|
|`remove_action_suffix`|Boolean|`false`|Removes "Action" suffixes from generated method names.|

Example `build.yaml`:
```yaml
targets:
  $default:
    builders:
      redux_action_extension_generator:
        options:
          state_type: AppState
          state_import_path: 'package:my_package/src/redux/state.dart'
          remove_action_suffix: true
```

[package:build_config]: https://pub.dev/packages/build_config

#### Importing types
If your actions use non-native types in their constructors, the generated file
won't import them. To resolve this, export the required types in your action
definition library:

```dart
import 'package:redux_action_extension_annotation/redux_action_extension_annotation.dart';

import 'complex_type.dart';

export 'complex_type.dart' show ComplexType;

class ExampleAction {
  final ComplexType exampleValue;
  
  @ActionExtension()
  const ExampleAction(this.exampleValue);
}
```

## Why?
As Dart is statically typed, and actions are usually classes with defined
fields, action creators aren't as important as they are when using JavaScript
Redux. They are useful, however, for restricting access to dispatching certain
actions.

Say, for example, a project has its business logic in its own package. A feature
that fetches data from an API is added. Actions like the following enable this
behaviour:

```dart
class FetchDataAction {
  const GetDataAction();
}

class DataFetchingAction {
  const DataFetchingAction();
}

class DataFetchedAction {
  final Data data;
  const DataFetchedAction(this.data);
}

class DataFetchFailedAction {
  const DataFetchFailedAction();
}
```

When a data fetch is requested from the presentation layer, `FetchDataAction` is
dispatched to the store. This is intercepted by middleware, which performs the
API request, dispatching `DataFetchingAction`, `DataFetchedAction`, and
`DataFetchFailedAction` actions to report progress.

Ideally, the progress actions should not be able to be dispatched from anything
other than the middleware. If they're dispatched by the presentation layer, the
state can be broken.

Using this package, this behaviour can be enforced.

```dart
class FetchDataAction {
  @ActionExtension()
  const GetDataAction();
}
```

If just the `FetchDataAction` has an extension method generated, the generated
file can be exposed to the presentation layer. When the presentation layer
requests the data, it can call `store.getData()`, and it's unable to dispatch
any actions that it shouldn't dispatch.