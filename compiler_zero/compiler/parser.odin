package v0compiler
import "core:fmt"


is_type :: proc(token: Token) -> bool {
	#partial switch token {
	case Token.TypeStruct:
		return true
	case Token.TypeEnum:
		return true
	case Token.TypeInt_8:
		return true
	case Token.TypeInt_32:
		return true
	case Token.TypeInt_64:
		return true
	case Token.TypeFloat_8:
		return true
	case Token.TypeFloat_32:
		return true
	case Token.TypeFloat_64:
		return true
	case Token.TypeUnsigned_8:
		return true
	case Token.TypeUnsigned_32:
		return true
	case Token.TypeUnsigned_64:
		return true
	case Token.TypeString:
		return true
	case Token.TypeMultistring:
		return true
	case Token.TypeChar:
		return true
	}
	return false
}

token_to_type :: proc(
	token: Token,
	value: string,
	handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	TypeHandle,
	Error,
) {

	#partial switch token {
	case Token.TypeStruct:
		return handles.struct_type, Error.None
	case Token.TypeEnum:
		return handles.enum_type, Error.None
	case Token.TypeInt_8:
		return handles.i_8, Error.None
	case Token.TypeInt_32:
		return handles.i_32, Error.None
	case Token.TypeInt_64:
		return handles.i_64, Error.None
	case Token.TypeFloat_8:
		return handles.u_8, Error.None
	case Token.TypeFloat_32:
		return handles.u_32, Error.None
	case Token.TypeFloat_64:
		return handles.u_64, Error.None
	case Token.TypeUnsigned_8:
		return handles.f_8, Error.None
	case Token.TypeUnsigned_32:
		return handles.f_32, Error.None
	case Token.TypeUnsigned_64:
		return handles.f_64, Error.None
	case Token.TypeString:
		return handles.string, Error.None
	case Token.TypeMultistring:
		return handles.multistring, Error.None
	case Token.TypeChar:
		return handles.char, Error.None
	}

	if token == Token.Identifier {

		len := cast(u32)len(type_record.types)

		for i: u32 = 0; i < len; i += 1 {
			if type_record.types[i].name == value {
				return i, Error.None
			}
		}
	}

	return 0, Error.UnknownType
}


parse_type :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	builtin_type_handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
) {

	// TODO: add parsing for structs and enums

	// now we are at the token after `type`
	if tokens[old_i] != Token.Identifier {
		return old_i, Error.ExpectedTypeIdentifier
	}

	type: Type

	type.name = values[old_i]
	i := old_i + 1

	// first check if a type with the same name exists
	for type in type_record.types {
		if type.name == values[old_i] {
			return old_i, Error.TypeRedeclaration
		}
	}

	if tokens[i] != Token.Colon {
		return i, Error.ExpectedColon
	}
	i += 1


	#partial switch tokens[i] {
	case Token.TypeStruct:
		type.builtin = BuiltinType.struct_type
	case Token.TypeEnum:
		type.builtin = BuiltinType.enum_type
	case Token.TypeInt_8:
		type.builtin = BuiltinType.i8
	case Token.TypeInt_32:
		type.builtin = BuiltinType.i32
	case Token.TypeInt_64:
		type.builtin = BuiltinType.i64
	case Token.TypeFloat_8:
		type.builtin = BuiltinType.f8
	case Token.TypeFloat_32:
		type.builtin = BuiltinType.f32
	case Token.TypeFloat_64:
		type.builtin = BuiltinType.f64
	case Token.TypeUnsigned_8:
		type.builtin = BuiltinType.u8
	case Token.TypeUnsigned_32:
		type.builtin = BuiltinType.u32
	case Token.TypeUnsigned_64:
		type.builtin = BuiltinType.u64
	case Token.TypeString:
		type.builtin = BuiltinType.string
	case Token.TypeMultistring:
		type.builtin = BuiltinType.multistring
	case Token.TypeChar:
		type.builtin = BuiltinType.char
	}

	type.is_custom = true
	log(INFO, fmt.aprintf("Parsed type definition ` %v `", type))
	append_elem(&type_record.types, type)

	return i, Error.None
}

parse_function_signature :: proc(
	old_i: int,
	elements: ^ElementStorage,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	builtin_type_handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
) {


	// now we are at the token after `fn`
	if tokens[old_i] != Token.Identifier {
		return 0, Error.ExpectedIdentifier
	}

	s := 0
	for element in elements.type {
		if element == ElementType.Function {
			if elements.data[s].(Function).name == values[old_i] {
				return old_i, Error.FunctionRedeclaration
			}
		}
		s += 1
	}

	function: Function

	function.name = values[old_i]
	i := old_i + 1

	if tokens[i] != Token.ParenthesisOpen {
		return 0, Error.ExpectedParen
	}

	// if all is fine, we collect the parameters
	NAME := 0
	COLON := 1
	TYPE := 2
	COMMA := 3
	param_step := 0

	for tokens[i] != Token.ParenthesisClose {
		i += 1

		if tokens[i] == Token.Identifier && param_step == NAME {
			append_elem(&function.param_names, values[i])
			param_step = COLON
			continue
		}

		if (tokens[i] == Token.Colon && param_step == COLON) {
			param_step = TYPE
			continue
		}

		if (tokens[i] == Token.Comma && param_step == COMMA) {
			param_step = NAME
			continue
		}

		if param_step == TYPE {
			type_handle, result := token_to_type(
				tokens[i],
				values[i],
				builtin_type_handles,
				type_record,
			)
			if result != Error.None {
				return i, result
			}
			append_elem(&function.param_types, type_handle)

			param_step = COMMA
			continue
		}
	}

	i += 1
	if tokens[i] == Token.CurlyBracketOpen {
		return i, Error.None
	} else if tokens[i] == Token.Colon {
		i += 1
	} else {
		return i, Error.ExpectedColonOrOpeningCurly

	}

	for tokens[i] != Token.CurlyBracketOpen {
		if tokens[i] == Token.Newline {
			i += 1
			continue
		}

		type_handle, result := token_to_type(
			tokens[i],
			values[i],
			builtin_type_handles,
			type_record,
		)
		if result != Error.None {
			return i, result
		}

		append_elem(&function.return_types, type_handle)
		i += 1

		// Skip newlines after a type.
		for tokens[i] == Token.Newline {
			i += 1
		}

		if tokens[i] == Token.CurlyBracketOpen {
			break
		}

		if tokens[i] != Token.Comma {
			return i, Error.UnexpectedToken
		}

		i += 1
	}

	log(INFO, fmt.aprintf("Parsed function definition ` %v `", function))
	append_elem(&elements.data, function)
	append_elem(&elements.type, ElementType.Function)

	return i, Error.None
}


// TODO: fix the declaration types mess
parse_expression :: proc(
	old_i: int,
	elements: ^ElementStorage,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
    n_of_expr: int, // length of the types array
) -> (
    // return the expression array
	int,
	Error,// -> take names and types as well
) {
  /*
     This function needs to know how many values the expression should output, and their types 
     And if the type isnt specified (in case of single variable) infer the type 
     In case of multiple variables, infer the types either way
     1. go through tokens until new line
     2. parse expressions between commas
     3. at each expression, infer its type, and match it to the desired output types 
     4. keep track of the count
  */

	expression: BinaryExpression

	i := old_i + 1

	return old_i, Error.None
}

ScopeBuffer :: struct {
	names: [dynamic]string,
	types: [dynamic]Type,
}

parse_declaration_or_assignement :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	elements: ^ElementStorage,
	scope_buffer: ^ScopeBuffer,
	handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
) {
	// token at old_i is an identifier
	i := old_i + 1

	ASSIGN: int : 0
	INIT: int : 1
	state: int

	names: [dynamic]string
	types: [dynamic]TypeHandle // either inferred from function calls OR
	append_elem(&names, values[old_i])

	for tokens[i] == Token.Identifier || tokens[i] == Token.Comma {
		if tokens[i] == Token.Identifier {
			append_elem(&names, values[i])
		}
		if tokens[i] == Token.Comma {
			if tokens[i - 1] == Token.Comma {return i, Error.UnexpectedComma}
		}
		i += 1
	}

	if tokens[i] == Token.Colon {
		state = INIT
		i += 1 // now past the semi colon
		if tokens[i] == Token.AssignOp { 	// variable declaration
			NO_TYPE_ANNOTATION :: true
			// NOTE: we allow redeclaration technically, the code generation for that is TBD
			i, err := parse_expression(i, elements, tokens, values)
		}
		if tokens[i] == Token.Colon { 	// constant declaration
			NO_TYPE_ANNOTATION :: true
			i, err := parse_expression(i, elements, tokens, values)
		}

		type_annotated := tokens[i] == Token.Identifier || is_type(tokens[i])
        if type_annotated {

			if len(names) > 1 {return i, Error.CannotAnnotateMultipleVars}
			
            type_handle, err := token_to_type(tokens[i], values[i], handles, type_record)
			
            if err != Error.None {return i, err}
            append_elem(&types, type_handle)
            i+=1
            
            if tokens[i] == Token.CurlyBracketOpen { } // TODO: parse enum or struct types (check backend type first)
            
            if tokens[i] == Token.AssignOp {
                i, err = parse_expression(i, elements, tokens, values)
            } 
            if tokens[i] == Token.Colon {
                i, err = parse_expression(i, elements, tokens, values)
            }
            return i, Error.UnexpectedToken // no
		}
		return i, Error.UnexpectedToken
	}
	return i, Error.None
}

parse_block :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	type_record: ^TypeStorage,
	handles: BuiltinHandles,
	elements: ^ElementStorage,
	signals: ^Signals,
	foreign_names: [dynamic]string, // i.e. parameter names in a function
) -> (
	int,
	Error,
) { 	// assuming tokens[old_i] is an opening bracket

	for name in foreign_names {

	}
	scope_buffer: ScopeBuffer

	i := old_i + 1

	for tokens[i] != Token.CurlyBracketClose {
		#partial switch tokens[i] {
		case Token.Identifier:
			{
				i, err := parse_declaration_or_assignement(
					i,
					tokens,
					values,
					elements,
					&scope_buffer,
					handles,
					type_record,
				)
				// ^will modify the scope buffer and add whatever needs to be added
			}
		}
	}

	return 0, Error.None

}


parse_token_stream :: proc(
	source_id: string,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	type_record: ^TypeStorage,
	elements: ^ElementStorage,
	signals: ^Signals,
) -> (
	int,
	Error,
) {


	// TODO:  *** Parse unary expressions, variable assignements, and binary expressions

	// TODO:  ** Parse conditionals

	// TODO:  ** Parse function bodies (aka parsing block with foreign params)

	// TODO:  * Parse function calls

	// TODO:  * Parse loops (last thing) // THEN: Code generation


	builtin_type_handles := store_builtin_types(type_record)

	i := 0
	err: Error

	// first we collect all signals
	for tokens[i] != Token.EOF {
		if tokens[i] == Token.KeywordSignal {
			i, err = parse_signal(i + 1, tokens, values, signals)
			if err != Error.None {
				return i, err
			}
		}
		i += 1
	}

	i = 0

	// then we collect all the declared types
	for tokens[i] != Token.EOF {
		if tokens[i] == Token.KeywordType {
			i, err = parse_type(i + 1, tokens, values, builtin_type_handles, type_record)
			if err != Error.None {
				return i, err
			}
		}
		i += 1
	}

	i = 0

	// then we collect all function signatures
	for tokens[i] != Token.EOF {

		#partial switch tokens[i] {

		case Token.KeywordFn:
			{
				i, err = parse_function_signature(
					i + 1,
					elements,
					tokens,
					values,
					builtin_type_handles,
					type_record,
				)
			}
		}
		if err != Error.None {
			return i, err
		}
		i += 1
	}


	// case Token.KeywordRun:
	// 	{
	// 		i, err = parse_block()  // with no usable variables from outside the block
	// 	}

	return 0, Error.None
}
