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
	type_record: ^TypeStorage,
) -> (
	TypeHandle,
	Error,
) {

	#partial switch token {
	case Token.TypeInt_8:
		return builtin_handles.i_8, Error.None
	case Token.TypeInt_32:
		return builtin_handles.i_32, Error.None
	case Token.TypeInt_64:
		return builtin_handles.i_64, Error.None
	case Token.TypeFloat_8:
		return builtin_handles.u_8, Error.None
	case Token.TypeFloat_32:
		return builtin_handles.u_32, Error.None
	case Token.TypeFloat_64:
		return builtin_handles.u_64, Error.None
	case Token.TypeUnsigned_8:
		return builtin_handles.f_8, Error.None
	case Token.TypeUnsigned_32:
		return builtin_handles.f_32, Error.None
	case Token.TypeUnsigned_64:
		return builtin_handles.f_64, Error.None
	case Token.TypeString:
		return builtin_handles.string, Error.None
	case Token.TypeMultistring:
		return builtin_handles.multistring, Error.None
	case Token.TypeChar:
		return builtin_handles.char, Error.None
	}

	if token == Token.Identifier {

		len := cast(u32)len(type_record.types)

		for i: u32 = 0; i < len; i += 1 {
            #partial switch type in type_record.types[i] {
			case NormalType:
				{
					if type.name == value {
						return i, Error.None
					}
				}
			case StructType:
				{
					if type.struct_name == value {
						return i, Error.None
					}
				}
			case EnumType:
				{
					if type.enum_name == value {
						return i, Error.None
					}
				}
            // TODO: Handle ArrayType
			}

		}
	}

	return 0, Error.UnknownType
}

parse_enum :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
	[dynamic]string,
) {
	variants: [dynamic]string
	if tokens[old_i] != Token.CurlyBracketOpen {
		return old_i, Error.ExpectedOpeningCurly, variants
	}

	i := old_i + 1
	COMMA :: 0
	IDENT :: 1
	expected := IDENT
	for tokens[i] != Token.CurlyBracketClose {
		#partial switch tokens[i] {
		case Token.Identifier:
			{
				if expected != IDENT {return i, Error.ExpectedComma, variants}
				append_elem(&variants, values[i])
				expected = COMMA
			}
		case Token.Comma:
			{
				if expected != COMMA {return i, Error.ExpectedIdentifier, variants}
				expected = IDENT
			}
		case Token.Newline:
			i += 1; continue
		case:
			return i, Error.UnexpectedToken, variants
		}
		i += 1
	}
	return i, Error.None, variants
}

parse_struct :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
	[dynamic]string,
	[dynamic]TypeHandle,
) {
	fields: [dynamic]string
	types: [dynamic]TypeHandle

	if tokens[old_i] != Token.CurlyBracketOpen {
		return old_i, Error.ExpectedOpeningCurly, fields, types
	}
	i := old_i + 1

	IDENT :: 0
	COLON :: 1
	TYPE :: 2
	COMMA :: 3

	expected := IDENT

	for tokens[i] != Token.CurlyBracketClose {
		#partial switch tokens[i] {
		case Token.Comma:
			{
				if expected != COMMA {return i, Error.ExpectedComma, fields, types}
				expected = IDENT
			}
		case Token.Colon:
			{
				if expected != COLON {return i, Error.ExpectedColon, fields, types}
				expected = TYPE
			}
		case Token.Newline:
			i += 1; continue

		case:
			{
				if expected == IDENT && tokens[i] == Token.Identifier {
					append_elem(&fields, values[i])
					expected = COLON
					i += 1; continue
				}
				type, err := token_to_type(tokens[i], values[i], type_record)
				if expected == TYPE && err == Error.None {
					append_elem(&types, type)
					expected = COMMA
					i += 1; continue
				}
				return i, err, fields, types
			}
		}
		i += 1
	}
	return i, Error.None, fields, types
}

parse_type :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	builtin_handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
) {

	// now we are at the token after `type`
	if tokens[old_i] != Token.Identifier {
		return old_i, Error.ExpectedTypeIdentifier
	}

	type_name := values[old_i]
	i := old_i + 1

	// first check if a type with the same name exists
	for t in type_record.types {
        #partial switch type in t {
		case NormalType:
			{
				if type.name == values[old_i] {
					return old_i, Error.TypeRedeclaration
				}
			}
		case StructType:
			{
				if type.struct_name == values[old_i] {
					return old_i, Error.TypeRedeclaration
				}
			}
		case EnumType:
			{
				if type.enum_name == values[old_i] {
					return old_i, Error.TypeRedeclaration
				}
			}
            // TODO: Handle ArrayType
		}
	}

	if tokens[i] != Token.Colon {
		return i, Error.ExpectedColon
	}
	i += 1

	type: Type

	#partial switch tokens[i] {
	case Token.TypeStruct:
		i, err, fields, types := parse_struct(
			i + 1,
			tokens,
			values,
			builtin_handles,
			type_record,
		)
		type = StructType {
			struct_name = type_name,
			field_names = fields,
			field_types = types,
		}
	case Token.TypeEnum:
		{
			i, err, variants := parse_enum(
				i + 1,
				tokens,
				values,
				type_record,
			)
			type = EnumType {
				enum_name     = type_name,
				variant_names = variants,
			}
		}
	case Token.TypeInt_8:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.i8,
		}
	case Token.TypeInt_32:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.i32,
		}
	case Token.TypeInt_64:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.i64,
		}
	case Token.TypeFloat_8:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.f8,
		}
	case Token.TypeFloat_32:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.f32,
		}
	case Token.TypeFloat_64:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.f64,
		}
	case Token.TypeUnsigned_8:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.u8,
		}
	case Token.TypeUnsigned_32:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.u32,
		}
	case Token.TypeUnsigned_64:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.u64,
		}
	case Token.TypeString:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.string,
		}
	case Token.TypeMultistring:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.multistring,
		}
	case Token.TypeChar:
		type = NormalType {
			name      = type_name,
			is_custom = true,
			builtin   = BuiltinType.char,
		}
	}

	log(INFO, fmt.aprintf("Parsed type definition ` %v `", type))
	append_elem(&type_record.types, type)

	return i, Error.None
}

parse_function_signature :: proc(
	old_i: int,
	elements: ^ElementStorage,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
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


check_special_type :: proc(
	i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	type_record: ^TypeStorage,
	scope: ScopeMetadata,
) {

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
	scope_metadata: ScopeMetadata
	// a block will inherit its scope metadata from outer blocks :
	//   * if the block is a function body -> takes the parameters + globals
	//   * if the block is a loop  or branch body -> all the scope around it (before it*)

	i := old_i + 1

	for tokens[i] != Token.CurlyBracketClose {
		#partial switch tokens[i] {
		case Token.Identifier:
			{
				i, err := parse_statement(
					i,
					tokens,
					values,
					elements,
					&scope_metadata,
					handles,
					type_record,
				)
				// ^will modify the scope metadata and add whatever needs to be added
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


	store_builtin_types(type_record)

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
			i, err = parse_type(i + 1, tokens, values, builtin_handles, type_record)
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
