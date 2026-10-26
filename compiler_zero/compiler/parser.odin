package v0compiler
import "core:fmt"


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

		len := cast(u32)len(type_record.types) - 1

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
	fmt.printfln("%s [INFO]: %s  Parsed type definition ` %v `", COLOR_GREEN, COLOR_RESET, type)
    append_elem(&type_record.types, type)

	return i, Error.None
}

parse_function_def :: proc(
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


	function: Function

	// now we are at the token after `fn`
	if tokens[old_i] != Token.Identifier {
		return 0, Error.ExpectedIdentifier
	}

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
			param_step += 1
			continue
		}

		if (tokens[i] == Token.Colon && param_step == COLON) ||
		   (tokens[i] == Token.Comma && param_step == COMMA) {
			param_step += 1
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
                fmt.println(result)
				return i, result
			}
			append_elem(&function.param_types, type_handle)

			param_step += 1
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

	fmt.printfln("%s [INFO]: %s  Parsed function definition ` %v `", COLOR_GREEN, COLOR_RESET, function)
	append_elem(&elements.data, function)
	append_elem(&elements.type, ElementType.Function)

	return i, Error.None
}


parse_expression :: proc(
	old_i: int,
	elements: ElementStorage,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
) -> (
	int,
	Error,
) {

	expression: BinaryExpression

	i := old_i + 1

	return old_i, Error.None
}


parse_token_stream :: proc(
	source_id: string,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
) -> (int, Error) {


	// TODO:  *** Parse unary expressions, variable assignements, and binary expressions

	// TODO:  ** Parse conditionals

	// TODO:  ** Parse function definitions

	// TODO:  ** Parse type declarations

	// TODO:  * Parse function calls

	// TODO:  * Parse loops (last thing) // THEN: Code generation


	type_record: TypeStorage
	builtin_type_handles := store_builtin_types(&type_record)
	elements: ElementStorage

	i := 0
	err: Error

    // first we collect all the declared types  TODO: and signals
	for tokens[i] != Token.EOF {
		 if tokens[i] == Token.KeywordType {
            i, err = parse_type(
                i + 1,
                tokens,
                values,
                builtin_type_handles,
                &type_record,
            )
            if err != Error.None {
                return i, err
            }
		}
		i += 1
	}

    i=0

	// for tokens[i] != Token.EOF {
	//
	// 	#partial switch tokens[i] {
	//
	// 	case Token.KeywordFn:
	// 		{
	// 			i, err = parse_function_def(
	// 				i + 1,
	// 				&elements,
	// 				tokens,
	// 				values,
	// 				builtin_type_handles,
	// 				&type_record,
	// 			)
	// 		}
	//
	//
	// 	}
	//
	// 	i += 1
	// }


		// case Token.KeywordRun:
		// 	{
		// 		i, err = parse_block()  // with no usable variables from outside the block
		// 	}

	return 0, Error.None
}
