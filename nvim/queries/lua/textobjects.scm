; extends

; 函数声明
[
;; local func
local_declaration: (function_declaration 
  name: (identifier) @custom.function.declare) 

;; global func
(function_declaration 
  name: (method_index_expression
    table: (identifier)
    method: (identifier) @custom.function.declare))

; 先声明，再赋值的func
(assignment_statement 
  (variable_list  
    name: (identifier) @custom.function.declare)
    (expression_list 
      value: (function_definition)))

; M.func = xxx
(function_declaration 
  name: (method_index_expression 
    table: (identifier)
    method: (identifier) @custom.function.declaration)
)
]



