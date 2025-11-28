; extends

; A robust, hybrid query for C++ function names.
; This version correctly identifies member functions inside classes
; while still avoiding matches inside function bodies or return types.

[
  ; --- Primary Declarators ---
  ; This single rule captures most cases by looking at what the declarator IS.
  ; It handles:
  ; - Member functions: void simple_method(); -> (field_identifier)
  ; - Global functions: int global_func(); -> (identifier)
  ; - Constructors: MyClass(); -> (type_identifier)
  ; - Destructors: ~MyClass(); -> (destructor_name)
  ; - Operators: operator==(); -> (operator_name)
  (function_declarator
    declarator: [
      (field_identifier)
      (identifier)
      (type_identifier)
      (destructor_name)
      (operator_name)
    ] @custom.function.declare)

  ; --- Qualified Declarators (Out-of-line definitions) ---
  ; This handles `void MyClass::func()`. We only want `func`.
  (function_declarator
    declarator: (qualified_identifier
      name: [
        (identifier)
        (type_identifier) ; For MyClass::MyClass()
        (destructor_name)
        (operator_name)
      ] @custom.function.declare))

  ; --- Trailing Return Type Declarators ---
  ; This handles `auto func() -> int`.
  ; (trailing_return_type_declarator
  ;   declarator: [
  ;     (field_identifier) ; For members
  ;     (identifier)       ; For non-members
  ;     (operator_name)
  ;   ] @custom.function.declare)
]
