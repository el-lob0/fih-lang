package v0compiler

import "core:fmt"
import "core:time"


main :: proc() {

    start := time.tick_now()

	test_file := "test.fih"

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
		}
	}

	fmt.println("[INFO]: ", msg)

    result := parse_token_stream(test_file, &tokens, &values)

    elapsed := time.tick_diff(start, time.tick_now())
    fmt.println("Elapsed:", elapsed)
	
}
