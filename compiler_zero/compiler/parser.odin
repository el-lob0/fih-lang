package v0compiler





parse_function :: proc(i: int) -> int {

    return i
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

    i := 0

    for tokens[i] != Token.EOF {
        
      #partial switch tokens[i] {

        case Token.KeywordFn: {
            i = parse_function(i+1)
        }
        case Token.KeywordRun: {
            i = parse_function(i+1)
        }
        case Token.KeywordType: {
            i = parse_function(i+1)
        }

        case: return Error.UnexpectedToken

        }



    }

    return Error.None
}




