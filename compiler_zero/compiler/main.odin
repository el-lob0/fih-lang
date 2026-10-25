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
				fmt.println("[ERROR]: Unexpected token, ", msg)
				return
			}
		case Error.ExpectedClosingSingleQuote:
			{
				fmt.println("[ERROR]: Expected closing `'`, ", msg)
				return
			}
		case Error.ExpectedClosingDoubleQuote:
			{
				fmt.println("[ERROR]: Expected closing `\"`, ", msg)
				return
			}
        case Error.UnknownType:
			{
				fmt.println("[ERROR]: Unknown type, ", msg)
				return
			}
		}
	}

	fmt.println("[INFO]: ", msg)

    result := parse_token_stream(test_file, &tokens, &values)

    // result printing or sumth
    RESET   :: "\x1b[0m"
    RED     :: "\x1b[31m"
    BOLD_GREEN   :: "\x1b[1;32m"
    YELLOW  :: "\x1b[33m"
    elapsed := time.tick_diff(start, time.tick_now())
    ok := fmt.printfln("\n  %s Completed %s [tokenization, parsing] in:  %.9fs", BOLD_GREEN, RESET, time.duration_seconds(elapsed))
	
}
