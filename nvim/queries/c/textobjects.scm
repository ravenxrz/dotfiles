; extends

; Capture the function name in C declarations/definitions for the custom
; [f/]f navigation mapping. The built-in C textobjects query provides
; @function.outer, but this config uses @custom.function.declare so jumps land
; on the function identifier rather than the whole function node.

(function_declarator
  declarator: (identifier) @custom.function.declare)

