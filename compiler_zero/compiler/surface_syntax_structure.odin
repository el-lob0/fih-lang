package v0compiler









ElementHandle :: u64

// Thing here can be a variable, an expression, a loop, a function. Anything. 
// ID is used here to make it easier to make operations on things with different types.

ElementType :: enum {
    // statements
    Loop,
    Function,
    Condition,
    Run,
    Match,
    Return,


/*
 For the types, Type is an element which is used in the logic.
 While DeclaredType is a statement element which is referred to inside of Type.
 It is stored along the other statements because its part of the syntax and to be referenced as well.
 */
    Type,
    DeclaredType, 

    // expressions (sub statements)
    UnaryExpression,
    BinaryExpression,

    VariableDeclaration,


    // values as variables
    VariableCopy, 
    VariableMove,

    // referenced by the variable elements
    Value,

    Pointer,

    FieldGroup,
}

ElementData :: union {
  Loop,
  Function,
  Condition,
  Run,
  Match,

  ReturnStatement,

  DeclaredType,

  UnaryExpression,
  BinaryExpression,

  VariableDeclaration,

  VariableMove,
  VariableCopy,

  Value,

  Pointer,

  FieldGroup,
}

ElementStorage :: struct {
    id: [dynamic]ElementHandle,
    type: [dynamic]ElementType,
    data: [dynamic]ElementData,
}


Loop :: struct {
    condition_handle: ElementHandle, // a boolean expression
    body: [dynamic]ElementHandle, // array of statements
}

Condition :: struct {
    condition_handle: ElementHandle, // a boolean expression
    then_body: [dynamic]ElementHandle, // array of statements
    else_body: [dynamic]ElementHandle, // array of statements
}

ReturnStatement :: [dynamic]ElementHandle // NOTE: i can refer to this with an element handle as well

Function :: struct {
    name: string,
    return_types: [dynamic]ElementHandle, // pointing to Type
    body: [dynamic]ElementHandle,
}

Run :: struct {
    body: [dynamic]ElementHandle,
    return_expression: ElementHandle, // an expression (a number, the exit code)
}

MatchCase :: struct {
    values: [dynamic]ElementHandle,
    body: [dynamic]ElementHandle,
}

Match :: struct {
    input: ElementHandle,
    cases: [dynamic]MatchCase,
}

UnaryExpression :: struct {
    operand: ElementHandle, // can be an expression or a value
    operation: UnaryOp,
}

BinaryExpression :: struct {
    left: ElementHandle, // can be an expression or a bool
    operation: BinaryOp,
    right: ElementHandle, // same ?
    // something like !some_var gets expanded to some_far != true
}

UnaryOp :: enum {
    PLUS,
    MINUS,
    NOT    
}

BinaryOp :: enum {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    AND,
    OR,
    EQUAL,
    NOT_EQUAL,
    LESS,
    GREATER,
    LESS_EQUAL,
    GREATER_EQUAL
}

Value :: struct {
    type: Type,
    value: string,
}

VariableDeclaration :: struct {
    name: string,
    type: Type,
    initializer: ElementHandle, // optional
}

VariableMove :: struct {
    source_variable: ElementHandle,
}

VariableCopy :: struct {
    source_variable: ElementHandle,
}

Pointer :: struct {
    pointee: ElementHandle, // a variable
}

DeclaredType :: struct {
    name: string,
    backend_type: BuiltinType, // this is an information for deciding which set of actions to take
    fields: ElementHandle, // points to a FieldGroup
}

// for enums and structs
FieldGroup :: struct {
    types: [dynamic]ElementHandle, // points to a Type
    names: [dynamic]string,
}

BuiltinType :: enum {
    i8,
    i32,
    i64,
    u8,
    u32,
    u64,
    f8,
    f32,
    f64,
    string,
    char,
    multistring,
    struct_type,
    enum_type,
}

Type :: struct {
    declared: ElementHandle, // points to a DeclaredType struct
    builtin: BuiltinType,
}


