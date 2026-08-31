class {{class_name}}Model {
{{#each fields}}  final {{dart_type}} {{name}};
{{/each}}
  const {{class_name}}Model({
{{#each fields}}    {{required_prefix}}this.{{name}},
{{/each}}  });

  factory {{class_name}}Model.fromJson(Map<String, dynamic> json) {
    return {{class_name}}Model(
{{#each fields}}      {{name}}: {{from_json_expr}},
{{/each}}    );
  }

  Map<String, dynamic> toJson() {
    return {
{{#each fields}}      {{json_key}}: {{to_json_expr}},
{{/each}}    };
  }
}
