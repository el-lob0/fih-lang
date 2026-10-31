package v0compiler

// statement = variable declaration or variable assignement

collect_var_names :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
) -> (
	int,
	Error,
	[dynamic][dynamic]string,
) {
	names: [dynamic][dynamic]string
	name: [dynamic]string
	i := old_i + 1
	// name[0] is the variable name, and all the following elems are fields
	for tokens[i] == Token.Identifier || tokens[i] == Token.Comma || tokens[i] == Token.Dot {
		if tokens[i] == Token.Identifier {
			append_elem(&name, values[i])
		}
		if tokens[i] == Token.Comma {
			if tokens[i - 1] == Token.Comma {return i - 1, Error.UnexpectedComma, names}
			append_elem(&names, name)
			clear(&name)
		}
		if tokens[i] == Token.Dot {
			if tokens[i - 1] == Token.Dot {
				return i - 1, Error.ExpectedField, names
			}
		}
		i += 1
	}

	return i, Error.None, names
}


collect_type_annotations :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
	[dynamic]TypeHandle,
) {
	types: [dynamic]TypeHandle
	i := old_i + 1
	is_valid := true
	was_type := false
	for is_valid {
		if is_type(tokens[i]) {
			if was_type {return i, Error.UnexpectedIdent, types}
			type_handle, err := token_to_type(tokens[i], values[i], type_record)
			append_elem(&types, type_handle)
			was_type = true
			i += 1
			continue
		}
		if tokens[i] == Token.Comma {
			if tokens[i - 1] == Token.Comma {return i - 1, Error.UnexpectedComma, types}
			i += 1
			continue
		}
		if tokens[i] == Token.AssignOp {return i, Error.None, types}
		return i, Error.UnexpectedToken, types
	}
	return i, Error.None, types
}


ScopeMetadata :: struct {
	// This is mainly to keep track of names and types before compilation
	names:        [dynamic][dynamic]string,
	types:        [dynamic]TypeHandle,
	expr_handles: [dynamic]ElementHandle,
}

enum_struct_declaration :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	elements: ^ElementStorage,
	scope_metadata: ^ScopeMetadata,
	handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
	[dynamic]ElementHandle,
) {

	expressions: [dynamic]ElementHandle
	i := old_i + 1

	return i, Error.None, expressions
}


check_var_type :: proc(
	type_record: TypeStorage,
	handle: TypeHandle,
	var_names: [dynamic][dynamic]string,
	i: int,
) -> Error {
	#partial switch t in type_record.types[handle] {
	case StructType:
		{
			is_field := false
			for field in t.field_names {
				if field == var_names[i][1] {is_field = true}
			}
			if is_field == false {return Error.UndeclaredVarAssignement}
		}
	case EnumType:
		return Error.TypeError
	case NormalType:
	}
	return Error.None
}


walk_identifier :: #force_inline proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
) -> (
	int,
	Error,
	Name,
) {
	i := old_i
	name: Name

	for tokens[i] == Token.Identifier {
		append_elem(&name, values[i])
		i += 1

		if tokens[i] != Token.Dot {
			break
		}

		i += 1
		if tokens[i] != Token.Identifier {
			return i, Error.ExpectedIdentifier, name
		}
	}

	return i, Error.None, name
}

check_var_name :: proc(scope_metadata: ScopeMetadata, var_name: Name) -> Error {

	for existing in scope_metadata.names {
		if var_name[0] == existing[0] {
			return Error.None
		}
	}
	return Error.UndeclaredVarInExpr
}


// TODO: *** parsing struct and enum stuff

parse_expressions :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	scope_metadata: ^ScopeMetadata,
	n_of_expr: int,
) -> (
	int,
	Error,
	[dynamic]Expression,
) {
	// types array is empty unless the expression is type annotated
	// which only works if its a single name

	parse_expr := #force_inline proc(
		old_i: int,
		tokens: ^[dynamic]Token,
		values: ^[dynamic]string,
		scope_metadata: ^ScopeMetadata,
	) -> (
		int,
		Error,
		Expression,
	) {
		// TODO: handle parenthesis count
		i := old_i
		OPERATOR :: 0
		OPERAND :: 1
		expect := OPERAND
		force_operand := false
		expression: Expression
		for tokens[i] != Token.Comma {
			i += 1
			if expect == OPERATOR {
				if force_operand {return i, Error.ExpectedOperand, expression}
				operator: Operand
				is_operator :=
					tokens[i] == Token.PlusOp ||
					tokens[i] == Token.MinusOp ||
					tokens[i] == Token.MultOp ||
					tokens[i] == Token.DivOp ||
					tokens[i] == Token.ModuloOp ||
					tokens[i] == Token.AssignOp ||
					tokens[i] == Token.EqualComparisonOp ||
					tokens[i] == Token.EqualOrLess ||
					tokens[i] == Token.EqualOrMore ||
					tokens[i] == Token.LessThan ||
					tokens[i] == Token.MoreThan ||
					tokens[i] == Token.NotEqualComparisonOp ||
					tokens[i] == Token.OR_ComparisonOp ||
					tokens[i] == Token.AND_ComparisonOp
				if is_operator {
					expect = OPERAND
					value: Value = values[i]
					operator := value
					append_elem(&expression.token, tokens[i])
					append_elem(&expression.value, operator)
				}
			}
			if expect == OPERAND {
				expect = OPERATOR
				operand: Operand
				err: Error
				if (tokens[i] == Token.MinusOp || tokens[i] == Token.NotPrefix) {
					expect = OPERAND
					value: Value = values[i]
					operator := value
					append_elem(&expression.token, tokens[i])
					append_elem(&expression.value, operator)
				}
				#partial switch tokens[i] {
				case Token.Identifier:
					{
						name: Name
						i, err, name = walk_identifier(i, tokens, values)
						if err != Error.None {return i, err, expression}
						err = check_var_name(scope_metadata^, name)
						if err != Error.None {return i, err, expression}
						operand = name
						append_elem(&expression.token, Token.Identifier)
						append_elem(&expression.value, operand)
					}
				case Token.String:
					{
						value: Value = values[i]
						operand = value
						append_elem(&expression.token, Token.String)
						append_elem(&expression.value, operand)
					}
				case Token.Number:
					{
						value: Value = values[i]
						operand = value
						append_elem(&expression.token, Token.Number)
						append_elem(&expression.value, operand)
					}
				case Token.Float:
					{
						value: Value = values[i]
						operand = value
						append_elem(&expression.token, Token.Float)
						append_elem(&expression.value, operand)
					}
				case:
					return i, Error.ExpectedOperand, expression
				}
			}
		}
		return i, Error.None, expression
	}

	expressions: [dynamic]Expression

	i := old_i + 1

	for tokens[i] != Token.Newline {
		if tokens[i] == Token.Comma {
			err: Error
			expr: Expression
			i, err, expr = parse_expr(i + 1, tokens, values, scope_metadata)
			if err != Error.None {return i, err, expressions}
			append_elem(&expressions, expr)
		}
		if len(expressions) > n_of_expr {return i, Error.TooManyExprs, expressions}
	}
	return old_i, Error.None, expressions
}


parse_statement :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
	elements: ^ElementStorage,
	scope_metadata: ^ScopeMetadata,
	handles: BuiltinHandles,
	type_record: ^TypeStorage,
) -> (
	int,
	Error,
	Statement,
) {
	i := old_i

	ASSIGNEMENT :: 0
	DECLARATION :: 1
	statement_type := 3
	const := false
	err: Error
	names: [dynamic][dynamic]string
	types: [dynamic]TypeHandle
	statement: Statement

	i, err, names = collect_var_names(i, tokens, values)

	if tokens[i] == Token.Colon {
		statement_type = DECLARATION
		i, err, types = collect_type_annotations(i, tokens, values, type_record)
		if tokens[i] == Token.Colon {
			i += 1
			const = true
		}
		if len(types) != 0 && len(names) > len(types) {
			return i - 1, Error.PartialTypeAnnotation, statement
		}
	}
	if tokens[i] == Token.AssignOp {
		statement_type = ASSIGNEMENT
	}
	// by now i know if its a constant, a normal declaration or an assignement
	if statement_type == 3 {return i, Error.UnexpectedToken, statement}

	number_of_expressions := len(names)
	parse_expressions(i, tokens, values, scope_metadata, number_of_expressions) // parses structs and enums too

    // TODO: *** checking expressions' types

    // TODO: * when a delcaration is returned, its data is extracted to the name_type table
	append_elems(&scope_metadata.names, ..names[:])
	append_elems(&scope_metadata.types, ..types[:]) // modified by expression parser
	return i, Error.None, statement
}
