package v0compiler


ElementHandle :: u64

TypeHandle :: u32

// Thing here can be a variable, an expression, a loop, a function. Anything.
// ID is used here to make it easier to make operations on things with different types.


ElementType :: enum {
	// statements
	Loop,
	Function,
	FunctionCall,
	Condition,
	Run,
	Match,
	Return,


	/*
 For the types, Type is an element which is used in the logic.
 While DeclaredType is a statement element which is referred to inside of Type.
 It is stored alongside the other statements because its part of the syntax and to be referenced as well.
 */
	Signal,

	// expressions (sub statements)
	UnaryExpression,
	Expression,
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
	FunctionCall,
	Condition,
	Run,
	Match,
	ReturnStatement,
	Signal,
	DeclaredType,
	Expression,
	VariableDeclaration,
	VariableAssignement,
	Value,
	Pointer,
	FieldGroup,
}

ElementStorage :: struct {
	type: [dynamic]ElementType,
	data: [dynamic]ElementData,
}

TypeStorage :: struct {
	types: [dynamic]Type,
}

Loop :: struct {
	condition_handle: ElementHandle, // a boolean expression
	body:             [dynamic]ElementHandle, // array of statements
}

Condition :: struct {
	condition_handle: ElementHandle, // a boolean expression
	then_body:        [dynamic]ElementHandle, // array of statements
	else_body:        [dynamic]ElementHandle, // array of statements
}

ReturnStatement :: [dynamic]ElementHandle // i can refer to this with an element handle as well
// ^ need to enforce that the length of this matches the length of the function's declared returns

Function :: struct {
	name:         string,
	param_names:  [dynamic]string, // size must
	param_types:  [dynamic]TypeHandle, // match here
	return_types: [dynamic]TypeHandle, // pointing to Type
	body:         [dynamic]ElementHandle,
}

FunctionCall :: struct {
	name:   string,
	params: [dynamic]ElementHandle, // is a raw value OR an identifier OR a function call
}
// C transpilation: Multiple return values need a defined C representation, since C functions return only one value directly. Options include a generated struct or output parameters. This decision can wait until the transpiler is implemented.

Run :: struct {
	body:              [dynamic]ElementHandle,
	return_expression: ElementHandle, // an expression (a number, the exit code)
}

MatchCase :: struct {
	values: [dynamic]ElementHandle,
	body:   [dynamic]ElementHandle,
}

Match :: struct {
	input: ElementHandle,
	cases: [dynamic]MatchCase,
}

Expression :: struct {
	token: [dynamic]Token,
	value: [dynamic]Operand,
}

Operand :: union {
    Value,
    Name,
}

Value :: string
Name :: [dynamic]string

Signal :: struct {
	name: string,
}

Statement :: union {
    VariableDeclaration,
    VariableAssignement
}

NameTypeTable :: struct {
    names: [dynamic]Name,
    types: [dynamic]TypeHandle,
    const: [dynamic]bool,
}

VariableDeclaration :: struct {
	names:        [dynamic]string,
	types:        [dynamic]TypeHandle,
	initializers: [dynamic]Expression,
	const:        bool,
}

VariableAssignement :: struct {
	names:       [dynamic]string,
	expressions: [dynamic]Expression,
}


Pointer :: struct {
	pointee: ElementHandle, // a variable
}

DeclaredType :: struct {
	name:         string,
	backend_type: BuiltinType, // this is an information for deciding which set of actions to take
	fields:       ElementHandle, // points to FieldGroup, applies for enums and structs only
}

// for enums and structs declaration
FieldGroup :: struct {
	types: [dynamic]TypeHandle, // points to a Type
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
}

NormalType :: struct {
	name:      string, // only when its a custom type
	is_custom: bool,
	builtin:   BuiltinType,
}

Type :: union {
	NormalType,
	StructType,
	EnumType,
	ArrayType,
}

StructType :: struct {
	struct_name: string,
	field_names: [dynamic]string,
	field_types: [dynamic]TypeHandle,
}

EnumType :: struct {
	enum_name:     string,
	variant_names: [dynamic]string,
}

ArrayType :: struct {
	name:         string,
	fixed:        bool,
	element_type: TypeHandle,
	initializer:  [dynamic]string, // resolved to names vs values, maybe keep it as tokens ?
}

DictionaryType :: struct {
	// placeholder
}


BuiltinHandles :: struct {
	i_8:         u32,
	i_32:        u32,
	i_64:        u32,
	u_8:         u32,
	u_32:        u32,
	u_64:        u32,
	f_8:         u32,
	f_32:        u32,
	f_64:        u32,
	string:      u32,
	char:        u32,
	multistring: u32,
}

store_builtin_types :: proc(record: ^TypeStorage) {
	i8 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.i8,
	}
	append_elem(&record.types, i8)

	i32 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.i32,
	}
	append_elem(&record.types, i32)

	i64 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.i64,
	}
	append_elem(&record.types, i64)

	u8 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.u8,
	}
	append_elem(&record.types, u8)

	u32 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.u32,
	}
	append_elem(&record.types, u32)

	u64 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.u64,
	}
	append_elem(&record.types, u64)

	f8 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.f8,
	}
	append_elem(&record.types, f8)

	f32 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.f32,
	}
	append_elem(&record.types, f32)

	f64 := NormalType {
		is_custom = false,
		builtin   = BuiltinType.f64,
	}
	append_elem(&record.types, f64)

	string := NormalType {
		is_custom = false,
		builtin   = BuiltinType.string,
	}
	append_elem(&record.types, string)

	char := NormalType {
		is_custom = false,
		builtin   = BuiltinType.char,
	}
	append_elem(&record.types, char)

	multistring := NormalType {
		is_custom = false,
		builtin   = BuiltinType.multistring,
	}
	append_elem(&record.types, multistring)

	// NOTE: ALL enum or struct types are custom types
}


builtin_handles :: BuiltinHandles {
	i_8         = 0,
	i_32        = 1,
	i_64        = 2,
	u_8         = 3,
	u_32        = 4,
	u_64        = 5,
	f_8         = 6,
	f_32        = 7,
	f_64        = 8,
	string      = 9,
	char        = 10,
	multistring = 11,
}
