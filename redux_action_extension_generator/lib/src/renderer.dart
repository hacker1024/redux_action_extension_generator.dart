import 'package:code_builder/code_builder.dart';
import 'package:redux_action_extension_generator/src/action.dart';
import 'package:redux_action_extension_generator/src/code_utils.dart';

/// The renderer is a callable class that renders parsed action information into
/// extension function source code.
class Renderer {
  /// Imports to include in the generated library.
  ///
  /// Keys are import URIs, and values are lists of types to import with the
  /// `show` keyword. An empty list will omit the `show` keyword.
  final Map<String, List<String>> imports;

  /// Behaves as described in [ActionExtensionGenerator.stateType].
  final String? stateType;

  /// The name of the extension.
  final String extensionName;

  /// A list of [Action]s to render.
  final List<Action> actions;

  const Renderer({
    required this.imports,
    this.stateType,
    required this.extensionName,
    required this.actions,
  });

  /// Performs the function described in the [Renderer] class documentation.
  String call() {
    final library = Library(
      (b) => b.body
        ..addAll(_buildImports())
        ..add(_buildExtension()),
    );

    return library
        .accept(DartEmitter(Allocator.simplePrefixing(), true, true))
        .toString();
  }

  /// Generates a collection of import directives.
  Iterable<Directive> _buildImports() => imports.entries
      .map((import) => Directive.import(import.key, show: import.value));

  /// Generates the extension.
  Extension _buildExtension() => Extension(
        (builder) => builder
          ..name = extensionName
          ..on = Reference('Store${stateType == null ? '' : '<$stateType>'}')
          ..methods.addAll(actions.map(_buildExtensionMethod)),
      );

  /// Generates an extension method that creates the given [action].
  Method _buildExtensionMethod(Action action) {
    // Convert the action constructor parameters to `package:source_gen` types.
    final parameters = action.constructorElement.parameters
        .map((parameter) => parameter.emittable)
        .toList(growable: false);

    // Convert the class type parameters to `package:source_gen` types.
    final types = action.constructorElement.enclosingElement.typeParameters
        .map((typeParameter) => typeParameter.emittable)
        .toList(growable: false);

    // Generate the method.
    return Method.returnsVoid(
      (builder) => builder
        ..name = action.extensionMethodName
        ..types.addAll(types)
        ..requiredParameters
            .addAll(parameters.where((parameter) => !parameter.named))
        ..optionalParameters
            .addAll(parameters.where((parameter) => parameter.named))
        ..lambda = true
        ..body = _buildExtensionMethodCode(action, types, parameters),
    );
  }

  /// Generates extension method code to create an action.
  ///
  /// This code should be used in methods with [Method.lambda] set to true.
  Code _buildExtensionMethodCode(
    Action action,
    List<Reference> types,
    List<Parameter> parameters,
  ) {
    // Retrieve the class and constructor names.
    final className = action.constructorElement.enclosingElement.name;
    final constructorName = action.constructorElement.name;

    // Set up a [StringBuffer] for code output.
    final buffer = StringBuffer();

    // Begin a [Store.dispatch] invocation.
    buffer.write('dispatch(');

    // If the action has a `const` constructor, and no regular or type
    // parameters are passed through, instantiate a `const` instance.
    if (action.constructorElement.isConst &&
        parameters.isEmpty &&
        types.isEmpty) {
      buffer.write('const ');
    }

    // Write the class name.
    buffer.write(className);

    // If there are any type parameters, add them.
    if (types.isNotEmpty) {
      buffer.write('<');
      for (final type in types) {
        buffer.write(type.symbol);
      }
      buffer.write('>');
    }

    // If the constructor has a name, add it.
    if (constructorName.isNotEmpty) {
      buffer.write('.');
      buffer.write(constructorName);
    }

    // Write the passed-through parameters.
    buffer.write('(');
    buffer.write(
      parameters
          .map((parameter) => parameter.named
              ? '${parameter.name}: ${parameter.name}'
              : parameter.name)
          .join(','),
    );
    buffer.write(')');

    // End the [Store.dispatch] invocation.
    buffer.write(')');

    // Return the code in a [Code] object.
    return Code(buffer.toString());
  }
}
