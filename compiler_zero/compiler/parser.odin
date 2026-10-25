package v0compiler
import "core:fmt"


parse_type_def :: proc() {}

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


parse_function_def :: proc(
	old_i: int,
	elements: ElementStorage,
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
				return 0, result
			}
			append_elem(&function.param_types, type_handle)

			param_step += 1
			continue
		}

		if tokens[i] == Token.Identifier && param_step == TYPE {
			// NOTE: under the assumption the type exists
			param_step += 1
			continue
		}
	}

    fmt.println("[INFO]:  Parsed function definition `", function, "`")

	return i, Error.None
}

parse_token_stream :: proc(
	source_id: string,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
) -> Error {



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

	for tokens[i] != Token.EOF {

		#partial switch tokens[i] {

		case Token.KeywordFn:
			{
				i, err = parse_function_def(i + 1, elements, tokens, values, builtin_type_handles, &type_record)
			}
		// case Token.KeywordRun:
		// 	{
		// 		i, err = parse_function_def(i + 1, elements, tokens, values, builtin_type_handles, &type_record)
		// 	}
		// case Token.KeywordType:
		// 	{
		//               fmt.println("before:", i)
		// 		i, err = parse_function_def(i + 1, elements, tokens, values, builtin_type_handles, &type_record)
		// 	}
		}

        i += 1
	}

	return Error.None
}
