import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

extension ParameterElementCode on ParameterElement {
  Parameter get emittable => Parameter(
        (builder) {
          if (documentationComment != null) {
            builder.docs.add(documentationComment);
          }
          builder
            ..required = isRequiredNamed
            ..covariant = isCovariant
            ..defaultTo =
                defaultValueCode == null ? null : Code(defaultValueCode)
            ..type = type.emittable
            ..types.addAll(
                typeParameters.map((typeParameter) => typeParameter.emittable))
            ..named = isNamed
            ..name = name;
        },
      );
}

extension TypeParameterElementCode on TypeParameterElement {
  Reference get emittable => Reference(name);
}

extension DartTypeCode on DartType {
  Reference get emittable => Reference(getDisplayString(withNullability: true));
}
