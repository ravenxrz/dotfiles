; extends

; function M.foo() ... end
(function_declaration
  name: (dot_index_expression
    table: (identifier)
    field: (identifier) @custom.function.declare)
  )

; function foo() ... end
(function_declaration
  name: (identifier) @custom.function.declare)

; local foo = function() ... end
(assignment_statement
  (variable_list
    (identifier) @custom.function.declare)
  (expression_list
    (function_definition)))

; M.foo = function() ... end
(assignment_statement
  (variable_list
    (dot_index_expression
      field: (identifier) @custom.function.declare))
  (expression_list
    (function_definition)))
