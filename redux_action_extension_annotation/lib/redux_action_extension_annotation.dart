library redux_action_extension_annotation;

/// An annotation to generate extension functions that create and dispatch an
/// action via the annotated action constructor.
class ActionExtension {
  /// A custom name for the extension function.
  final String? name;

  /// Additional imports to include.
  @Deprecated(
      'This parameter is deprecated. Use export directives to expose required types instead.')
  final List<String> additionalImports;

  const ActionExtension({
    this.name,
    this.additionalImports = const [],
  });
}
