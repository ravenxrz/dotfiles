; extends 

; 函数声明
[
  ;; 普通函数定义
  (function_definition
    type: (primitive_type)
    declarator: (function_declarator
      declarator: (identifier) @custom.function.declare
      parameters: (parameter_list))
    ) 

  ;; 带命名空间的普通函数定义
  (function_definition
    declarator: (function_declarator
      declarator: (qualified_identifier
        scope: (namespace_identifier)
        name: (identifier) @custom.function.declare))
    ) 

  ;; 多层嵌套命名空间函数定义
  (function_definition
    type: (primitive_type)
    declarator: (function_declarator
      declarator: (qualified_identifier
        scope: (namespace_identifier)
        name: (qualified_identifier
          scope: (namespace_identifier)
          name: (identifier) @custom.function.declare)))
    ) 

  ;; 析构函数定义
  (function_definition
        declarator: (function_declarator
            declarator: (qualified_identifier
                name: (destructor_name) @custom.function.declare
            )
        )
    ) 

  ;; 普通成员函数定义(out define)
  (function_definition
    type: (primitive_type)
    declarator: (function_declarator
      declarator: (field_identifier) @custom.function.declare
      )) 

  ;; 类定义中的函数定义(inner define)
(class_specifier
    body: (field_declaration_list
        (function_definition
            declarator: (function_declarator
                declarator: (identifier) @custom.function.declare
            )
        )
    )
) 

; 函数声明
(declaration 
  declarator: (function_declarator 
    declarator: (identifier) @custom.function.declare
    ))

; 析构函数声明
(declaration
  declarator: (function_declarator 
    declarator: (destructor_name) @custom.function.declare
    ))

; 函数声明
(field_declaration 
type: (primitive_type) 
declarator: (function_declarator 
  declarator: (field_identifier) @custom.function.declare 
  ))
]
