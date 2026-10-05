package v0compiler

import "core:fmt"





main :: proc() -> int {
    test_file := "test.fih"

    tokens, values, positions, err, msg := file_to_tokens(test_file)

    if err != Error.None {
        #partial switch err {
            case Error.UnexpectedToken: {
                fmt.println("[ERROR]: Unexpected token, ", msg)
                return 1
            }
            case Error.ExpectedClosingSingleQuote: {
                fmt.println("[ERROR]: Expected closing `'`, ", msg)
                return 1
            }
            case Error.ExpectedClosingDoubleQuote: {
                fmt.println("[ERROR]: Expected closing `\"`, ", msg)
                return 1
            }
        }
    }

    fmt.println("[INFO]: ", msg)

    for t in tokens {
        fmt.print(t, "; ")
    }

    return 0
}

