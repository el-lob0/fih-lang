package v0compiler

import "core:fmt"
import "core:time"

/*
 TODO: first parse type declarations and add them to the type record
       then parse expressions (probably the biggest pain) and variable declaratioons
       then parse code blocks (conditions, loops)
       and finally parse function calls
   */

main :: proc() {

    start := time.tick_now()

    test_file := "test.fih" // relative to where the command is run

    tokens, values, positions, err, msg := file_to_tokens(test_file)

    if err != Error.None {
        #partial switch err {
        case Error.UnexpectedToken:
            {
                fmt.printfln("%s [ERROR]: %s Unexpected token, %s ", COLOR_RED, COLOR_RESET, msg)
                return
            }
        case Error.ExpectedClosingSingleQuote:
            {
                fmt.printfln("%s [ERROR]: %s Expected closing `'`, %s ", COLOR_RED, COLOR_RESET, msg)
                return
            }
        case Error.ExpectedClosingDoubleQuote:
            {
                fmt.printfln("%s [ERROR]: %s Expected closing `\"`, %s ", COLOR_RED, COLOR_RESET, msg)
                return
            }
        case Error.UnknownType:
            {
                fmt.printfln("%s [ERROR]: %s Unknown type, %s ", COLOR_RED, COLOR_RESET, msg)
                return
            }
        }
    }

    fmt.printfln("%s [INFO]: %s %s", COLOR_GREEN, COLOR_RESET, msg)

    result := parse_token_stream(test_file, &tokens, &values)

    elapsed := time.tick_diff(start, time.tick_now())
    ok := fmt.printfln("\n        %s Completed %s in:  %.9fs", COLOR_BOLD_GREEN, COLOR_RESET, time.duration_seconds(elapsed))
	
}
