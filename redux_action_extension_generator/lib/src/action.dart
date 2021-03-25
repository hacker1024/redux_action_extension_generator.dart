import 'package:analyzer/dart/element/element.dart';
import 'package:redux_action_extension_annotation/redux_action_extension_annotation.dart';

class Action {
  final String extensionMethodName;
  final ActionExtension annotation;
  final ConstructorElement constructorElement;

  const Action(
      this.extensionMethodName, this.annotation, this.constructorElement);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Action &&
          runtimeType == other.runtimeType &&
          extensionMethodName == other.extensionMethodName &&
          annotation == other.annotation &&
          constructorElement == other.constructorElement;

  @override
  int get hashCode =>
      extensionMethodName.hashCode ^
      annotation.hashCode ^
      constructorElement.hashCode;
}
