package v0compiler

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"



Token :: enum {
    CurlyBracketOpen,
    CurlyBracketClose,
    SquareBracketOpen,
    SquareBracketClose,
    ParenthesisOpen,
    ParenthesisClose,
    DoubleQuoteOpen,
    DoubleQuoteClose,
    TildeOpen,
    TildeClose,
    SingleQuoteOpen,
    SingleQuoteClose,
    Identifier,
    KeywordIf,
    KeywordElse,
    KeywordRun,
    KeywordLoop,
    KeywordArray,
    KeywordFn,
    KeywordType,
    // types
    TypeStruct,
    TypeEnum,
    TypeInt_8,
    TypeInt_32,
    TypeInt_64,
    TypeUnsigned_8,
    TypeUnsigned_32,
    TypeUnsigned_64,
    TypeFloat_8,
    TypeFloat_32,
    TypeFloat_64,
    TypeString,
    TypeChar,
    // ----------- 
    Number,
    String,
    Char,
    PlusOp,
    MinusOp,
    MultOp,
    DivOp,
    ModuloOp,
    AssignOp,
    EqualComparisonOp,
    EqualOrLess,
    EqualOrMore,
    LessThan,
    MoreThan,
    NotEqualComparisonOp,
    OR_ComparisonOp,
    AND_ComparisonOp,
    NotPrefix,
    Newline,
    Dot,
    Comma,
    SemiColon,
    Colon,
    Hashtag,
    Tag,
    ReferenceOp,
    EOF,
    None,
}

StringState :: enum {
  Inside,
  Outside
}

Token_position :: struct {
  line: u32,
  col: u32,
}

is_numerical :: proc(str: string) -> bool {
    is_numerical := true
    for char in str {
        if !((char >= '0' && char <= '9') || char == '.') {
            is_numerical = false
            break
        }
    }
    return is_numerical
}

// any character that can't be in a type, keyword, or identifier returns false
interruption_met :: proc(char: rune) -> bool {
    is_literal := false

    if !((char >= 'a' && char <= 'z') || 
      (char >= 'A' && char <= 'Z') || 
      (char >= '0' && char <= '9') || 
      char == '_' || char == ' ') {
        is_literal = true
    }
    
    return is_literal   
}

tokenize_word :: proc(word: string) -> (Token, string) {

      is_key := word =="run" || word == "loop" || word == "if" || word =="else" || word == "array" || word == "fn" || 
                          word == "type"

      is_type := word =="i8" || word == "u8" || word == "f8" || word =="i32" || word == "u32" || word == "f32" || 
                          word == "i64" || word == "u64" || word == "f64" ||
                          word == "string" || word == "char" || 
                          word == "struct" || word == "enum"

      if is_numerical(word) {
          return Token.Number, word
      }

      token := Token.Identifier
      if !is_key && !is_type {
          return token, word         
      }


      switch word {
  
      case "run": return Token.KeywordRun, ""
      case "loop": return Token.KeywordLoop, ""
      case "if": return Token.KeywordIf, ""
      case "else": return Token.KeywordElse, ""
      case "array": return Token.KeywordArray, ""
      case "fn": return Token.KeywordFn, ""
      case "type": return Token.KeywordType, ""

      case "i8": return Token.TypeInt_8, ""
      case "i32": return Token.TypeInt_32, ""
      case "i64": return Token.TypeInt_64, ""
      case "u8": return Token.TypeUnsigned_8, ""
      case "f8": return Token.TypeUnsigned_32, ""
      case "u32": return Token.TypeUnsigned_64, ""
      case "u64": return Token.TypeFloat_8, ""
      case "f32": return Token.TypeFloat_32, ""
      case "f64": return Token.TypeFloat_64, ""
      case "string": return Token.TypeString, ""
      case "char": return Token.TypeChar, ""
      case "struct": return Token.TypeStruct, ""
      case "enum": return Token.TypeEnum, ""
      }

      return token, word // obsolete but ye         

}

append_token :: proc(tokens: ^[dynamic]Token, values: ^[dynamic]string, positions: ^[dynamic]Token_position, 
                         token: Token, value: string, position: Token_position) {
    append_elem(tokens, token)
    append_elem(values, value)   
    append_elem(positions, position)   
}

tokenize :: proc (tokens: ^[dynamic]Token, values: ^[dynamic]string, positions: ^[dynamic]Token_position, file: string) -> (Error, u32, u32) {
    buffer : [dynamic]u8

    line : u32 = 1
    col : u32 = 0

    in_single_quote := false
    char_count := 0
    in_double_quote := false

    escape := false
    comment := false
    multi_string := false
    previous_byte: rune = ' '

    for char in file {

        col += 1
      
        position := Token_position {
            line,
            col,
        }

        // WARN: Later, maybe next compiler, i'd like to implement maybe comments 
        // that are kept for logging purposes (with special syntax etc)
        if comment {
            if char == '\n' {
                comment = false
            } else {
                previous_byte = char
                continue
            }
        }


        // TODO: check for an invalid 2 byte succession (like | and then whitespace)

        //----------------------------

        if interruption_met(char) && len(buffer) > 0 {
            word, err := strings.clone(string(buffer[:]))
            token, value := tokenize_word(word)
            append_elem(tokens, token)
            append_elem(values, value)
            append_elem(positions, position)   
            clear(&buffer)
        }

        // ----------------------- CHAR AND STRING ---------------------

        if in_single_quote {
            char_count += 1
            // escape char check and logic
        }
        if char_count > 2 {
            return Error.ExpectedClosingSingleQuote, line, col 
        }

        if in_double_quote {
            if char == '\n' {
                return Error.ExpectedClosingDoubleQuote, line, col
            }
            append_elem(&buffer, u8(char))
            previous_byte = char
            continue
        }
        if in_single_quote && char != '\'' {
            append_elem(tokens, Token.Char)
            append_elem(values, fmt.tprintf("%c", char))
            append_elem(positions, position)   
            previous_byte = char
            continue
        }

        // ------------------- pre switch checks --------------

        if previous_byte == '=' && char != '=' {
            append_elem(tokens, Token.AssignOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        if previous_byte == '/' && char != '/' {
            append_elem(tokens, Token.DivOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        if previous_byte == '!' && char != '=' {
            append_elem(tokens, Token.NotPrefix)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        if previous_byte == '&' && char != '&' {
            append_elem(tokens, Token.ReferenceOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        // -------------------- end checks -----------------

        switch char {
        case '"': {
            if in_double_quote && !in_single_quote && char == '"' {

                append_elem(tokens, Token.DoubleQuoteClose)
                append_elem(values, "")
                append_elem(positions, position)   

                append_elem(tokens, Token.String)
                append_elem(values, string(buffer[:]))
                append_elem(positions, position)   

                in_double_quote = false
            }
            if !in_double_quote && !in_single_quote {
 
               append_elem(tokens, Token.DoubleQuoteOpen)
               append_elem(values, "")
               append_elem(positions, position)   

               in_double_quote = true
            }
        }
        case '\'': {
            if !in_single_quote {
                in_single_quote = true
                append_elem(tokens, Token.SingleQuoteOpen)
                append_elem(values, "")
                append_elem(positions, position)   
            }
            if in_single_quote {
                char_count = 0

                append_elem(tokens, Token.SingleQuoteClose)
                append_elem(values, "")
                append_elem(positions, position)   
            }
        }
        // ------------------------ END CHAR AND STRING -------------------

        // ------------------------ MATH OPERATORS ------------------------
        case '+': {
            append_elem(tokens, Token.PlusOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }
        case '-': {
            append_elem(tokens, Token.MinusOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }
        case '*': {
            append_elem(tokens, Token.MultOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }
        case '/': {
            if previous_byte == '/' {
                comment = true
            } // else: skip; resolved in next iteration
        }
        case '%': {
            append_elem(tokens, Token.ModuloOp)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        // -----------------------  BOOL OPERATORS (+assign) ---------------- 
        case '|': {
            if previous_byte == '|' {
                append_elem(tokens, Token.OR_ComparisonOp)
                append_elem(values, "")
                append_elem(positions, position)   
            } // else do nothing, lone | is invalid
        }
        case '&': {
            if previous_byte == '&' {
                append_elem(tokens, Token.AND_ComparisonOp)
                append_elem(values, "")
                append_elem(positions, position)   
            } // else do nothing, lone & is a reference
        }
        case '=': {
            if previous_byte == '=' {
                append_elem(tokens, Token.EqualComparisonOp)
                append_elem(values, "")
                append_elem(positions, position)   
            } else if previous_byte == '>' {
                append_elem(tokens, Token.EqualOrMore)
                append_elem(values, "")
                append_elem(positions, position)   
            } else if previous_byte == '<' {
                append_elem(tokens, Token.EqualOrLess)
                append_elem(values, "")
                append_elem(positions, position)   
            } else if previous_byte == '!' {
                append_elem(tokens, Token.NotEqualComparisonOp)
                append_elem(values, "")
                append_elem(positions, position)   
            }
            // else is handled later when next byte is confirmed not to be equal
        }
        case '>': {
            if previous_byte == '=' {
                append_elem(tokens, Token.EqualOrMore)
                append_elem(values, "")
                append_elem(positions, position)   
            } else {
                append_elem(tokens, Token.MoreThan)
                append_elem(values, "")
                append_elem(positions, position)   
            }
        }
        case '<': {
            if previous_byte == '=' {
                append_elem(tokens, Token.EqualOrLess)
                append_elem(values, "")
                append_elem(positions, position)   
            } else {
                append_elem(tokens, Token.LessThan)
                append_elem(values, "")
                append_elem(positions, position)   
            }
        }
        case '!': {} // handled in = case and in pre switch checks

        // -------------------------- DELIMITERS -----------------------------
        case '{': {
            append_elem(tokens, Token.CurlyBracketOpen)
            append_elem(values, "")
            append_elem(positions, position)   
        }
        case '}': {
            append_elem(tokens, Token.CurlyBracketClose)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case '(': {
            append_elem(tokens, Token.ParenthesisOpen)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case ')': {
            append_elem(tokens, Token.ParenthesisClose)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case '[': {
            append_elem(tokens, Token.SquareBracketOpen)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case ']': {
            append_elem(tokens, Token.SquareBracketClose)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case ':': {
            append_elem(tokens, Token.Colon)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case '.': {
            append_elem(tokens, Token.Dot)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case ',': {
            append_elem(tokens, Token.Comma)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case ';': {
            append_elem(tokens, Token.SemiColon)
            append_elem(values, "")
    append_elem(positions, position)   
        }
        case '`': {
            if multi_string {
                append_elem(tokens, Token.TildeClose)
                append_elem(values, "")
                append_elem(positions, position)   
                multi_string := false
            } else {
                append_elem(tokens, Token.TildeOpen)
                append_elem(values, "")
                append_elem(positions, position)   
                multi_string := true
            }
        }

        // ----------------------- SPECIAL CHARS ----------------------------------
        // whitespace, where i resolve the buffer if it contains something
        case ' ', '\n', '\r', '\t': {
            if len(buffer) > 0 {
                word, err := strings.clone(string(buffer[:]))
                token, value := tokenize_word(word)
                append_elem(tokens, token)
                append_elem(values, value)
                append_elem(positions, position)   
                clear(&buffer)
            }
            if char == '\n' {
                append_elem(tokens, Token.Newline)
                append_elem(values, "")
                append_elem(positions, position)   
                line += 1
                col = 0
            }
        }
        // escapes
        case '\\': {
            escape = true
        }
        case '@': {
            append_elem(tokens, Token.Tag)
            append_elem(values, "")
            append_elem(positions, position)   
        }
        case '#': {
            append_elem(tokens, Token.Hashtag)
            append_elem(values, "")
            append_elem(positions, position)   
        }

        // ------------- CHARS THAT AREN'T PART OF THE SYNTAX (YET) ---------------------
        // return unexpected token error
        case '?': { 
            return Error.UnexpectedToken, line, col
        }
        case '^': { 
            return Error.UnexpectedToken, line, col
        }
        case '~': { 
            return Error.UnexpectedToken, line, col
        }

        // ------------------ LETTERS AND NUMBERS ---------------------------------------
        case: {
            append_elem(&buffer, u8(char))
        }
        }
        previous_byte = char

    }


    append_elem(tokens, Token.EOF)
    append_elem(values, "")
    return Error.None, line, col
}



file_to_tokens :: proc(filepath: string) -> ([dynamic]Token, [dynamic]string, [dynamic]Token_position, Error, string) {
    tokens : [dynamic]Token
    values : [dynamic]string
    positions: [dynamic]Token_position
 
    raw_file, read_error := os.read_entire_file_from_filename(filepath)
    
    err, err_line, err_col := tokenize(&tokens, &values, &positions, string(raw_file))
    defer delete(raw_file, context.allocator)


    if err != Error.None {
        clear(&tokens)
        clear(&values)
        clear(&positions)
        return tokens, values, positions, err, fmt.tprintf("at %d:%d", err_line, err_col)
    } 

    return tokens, values, positions, Error.None, fmt.tprintf("Tokenized file: %s", filepath)
}
