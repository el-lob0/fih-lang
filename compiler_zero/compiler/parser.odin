package v0compiler







parse_function :: proc(old_i: int, elements: ElementStorage, tokens: ^[dynamic]Token, values: ^[dynamic]string) -> (int, Error) {
    // now we are at the token after `fn`
    if tokens[old_i] != Token.Identifier {
        return 0, Error.ExpectedIdentifier
    }

    function_name := values[old_i]
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

        token_is_type : = tokens[i] == Token.TypeInt_8 || tokens[i] == Token.TypeInt_32 || tokens[i] == Token.TypeInt_64 ||
           tokens[i] == Token.TypeUnsigned_8 || tokens[i] == Token.TypeUnsigned_32 || tokens[i] == Token.TypeUnsigned_64 ||
           tokens[i] == Token.TypeFloat_8 || tokens[i] == Token.TypeFloat_32 || tokens[i] == Token.TypeFloat_64 ||
           tokens[i] == Token.TypeString || tokens[i] == Token.TypeChar

        if tokens[i] == Token.Identifier && param_step == NAME {
              
            param_step += 1
        }

        if tokens[i] == Token.Colon && param_step == COLON {
            
            param_step += 1
        }

        if token_is_type && param_step == TYPE {
            
            param_step += 1
        }

        if tokens[i] == Token.Identifier && param_step == TYPE {
            // NOTE: for now we assume this is a declared type. Later, we check if it was actually declared anywhere
            param_step += 1
        }

        if tokens[i] == Token.Comma && param_step == COMMA {
            
            param_step += 1
        }
    }


    

    return i, Error.None
}

parse_token_stream :: proc(source_id: string, tokens: ^[dynamic]Token, values: ^[dynamic]string) -> Error {

   
    /* EXAMPLE TOKENS:

       Newline ; Newline ; Newline ; Newline ; 

       KeywordRun ; CurlyBracketOpen ; Newline ; 

       KeywordLoop ; ParenthesisOpen ; TypeInt_32 ; Colon ; Identifier ; AssignOp ; Number ; Dot ; Number ; ParenthesisClose ; 

       LessThan ; Identifier ; CurlyBracketOpen ; Newline ; 

       Identifier ; Dot ; Identifier ; AssignOp ; Identifier ; PlusOp ; Identifier ; Newline ; 

       CurlyBracketClose ; Newline ; 

       CurlyBracketClose ; Newline ; %
     */

    elements: ElementStorage

    i := 0
    err : Error


    for tokens[i] != Token.EOF {
        
      #partial switch tokens[i] {

        case Token.KeywordFn: {
            i, err = parse_function(i+1, elements, tokens, values)
        }
        case Token.KeywordRun: {
            i, err = parse_function(i+1, elements, tokens, values)
        }
        case Token.KeywordType: {
            i, err = parse_function(i+1, elements, tokens, values)
        }

        case: return Error.UnexpectedToken

        }
    }

    return Error.None
}




