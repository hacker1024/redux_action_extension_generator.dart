import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:redux_action_extension_annotation/redux_action_extension_annotation.dart';
import 'package:redux_action_extension_generator/src/action.dart';
import 'package:redux_action_extension_generator/src/renderer.dart';
import 'package:source_gen/source_gen.dart';

/// A generator to generate extension functions to create actions annotated with
/// the [ActionExtension] annotation.
class ActionExtensionGenerator extends Generator {
  /// The type name of the store's state object. If this is null, the extension
  /// functions will apply to `Store<dynamic>`.
  ///
  /// If this is set, [stateImportPath] must also be set.
  final String? stateType;

  /// The URI of the library containing the [stateType]. This may be `null` if
  /// no [stateType] is used.
  final String? stateImportPath;

  /// If true, "Action" will be removed from the beginning of extension function
  /// names.
  ///
  /// This does not apply to actions annotated with a custom name.
  final bool removeActionPrefix;

  /// Like [removeActionPrefix], but applies to the end instead of the
  /// beginning.
  final bool removeActionSuffix;

  const ActionExtensionGenerator({
    this.stateType,
    this.stateImportPath,
    required this.removeActionPrefix,
    required this.removeActionSuffix,
  }) : assert((stateType == null && stateImportPath == null) ||
            (stateType != null && stateImportPath != null));

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final actions = _findActions(library).toList(growable: false);
    if (actions.isEmpty) return null;

    final renderer = Renderer(
      imports: {
        'package:redux/redux.dart': const ['Store'],
        if (stateImportPath != null) stateImportPath!: [stateType!],
        ..._calculateActionImports(
          library,
          actions,
          limitToActionClasses: false,
        ),
        for (final additionalImport
            // ignore: deprecated_member_use
            in actions.expand((action) => action.annotation.additionalImports))
          additionalImport: const [],
      },
      stateType: stateType,
      extensionName: _calculateExtensionName(library),
      actions: actions,
    );
    return renderer();
  }

  /// Searches the [library] for annotated action constructors, and parses them
  /// into a collection of [Action]s.
  Iterable<Action> _findActions(LibraryReader library) sync* {
    for (final constructorElement in library.classes
        .expand((classElement) => classElement.constructors)) {
      final annotation = const TypeChecker.fromRuntime(ActionExtension)
          .firstAnnotationOfExact(constructorElement);
      if (annotation != null) {
        yield _parseAction(
          _parseAnnotation(ConstantReader(annotation)),
          constructorElement,
        );
      }
    }
  }

  /// Parses a located [ActionExtension] annotation.
  ActionExtension _parseAnnotation(ConstantReader constantReader) =>
      ActionExtension(
        name: constantReader.peek('name')?.stringValue,
        additionalImports: constantReader
            .read('additionalImports')
            .listValue
            .map((dartObject) => dartObject.toStringValue()!)
            .toList(growable: false),
      );

  /// Parses a located action annotation and constructor.
  Action _parseAction(
    ActionExtension annotation,
    ConstructorElement element,
  ) =>
      Action(
        _calculateExtensionMethodName(annotation, element),
        annotation,
        element,
      );

  /// Calculates an appropriate name for an extension on actions from the given
  /// library.
  String _calculateExtensionName(LibraryReader library) =>
      '${basenameWithoutExtension(library.element.source.uri.pathSegments.last).pascalCase}ActionExtensions';

  /// Calculates an action extension method name, taking prefixes, suffixes,
  /// and custom names into account.
  String _calculateExtensionMethodName(
    ActionExtension annotation,
    ConstructorElement element,
  ) {
    var name = annotation.name;
    if (name == null) {
      name = element.enclosingElement.name;
      if (removeActionPrefix && name.startsWith('Action')) {
        name = name.substring('Action'.length);
      }
      if (removeActionSuffix && name.endsWith('Action')) {
        name = name.substring(0, name.length - 'Action'.length);
      }
      name = '$name.${element.name}'.camelCase;
    }
    return name;
  }

  /// Extracts required import URIs from a collection of actions.
  ///
  /// If [limitToActionClasses] is set, the resultant map values will contain
  /// types to explicitly show in the import statement.
  Map<String, List<String>> _calculateActionImports(
    LibraryReader library,
    Iterable<Action> actions, {
    bool limitToActionClasses = true,
  }) {
    final actionImports = <String, Set<String>>{};
    for (final action in actions) {
      final importPath =
          library.pathToElement(action.constructorElement).toString();
      final importClasses = actionImports[importPath];
      late final className = action.constructorElement.enclosingElement.name;
      if (importClasses == null) {
        actionImports[importPath] = {if (limitToActionClasses) className};
      } else {
        if (limitToActionClasses) importClasses.add(className);
      }
    }
    return {
      for (final entry in actionImports.entries)
        entry.key: entry.value.toList(growable: false)
    };
  }
}
