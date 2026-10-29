package v0compiler

import "core:fmt"
import "core:time"


// NOTE: to make global std functions work, make them virtually inside the same package 
//  so basically function call checks std function as well as package functions 
//  and adds them to the element storage if they are called 
//  (basically std functions are written in the c file if they are called)

main :: proc() {

	start := time.tick_now()

	test_file := "test.fih" // relative to where the command is run

	tokens, values, positions, err, msg := file_to_tokens(test_file)

	if err != Error.None {
		#partial switch err {
		case Error.UnexpectedToken:
			{
				log(ERROR, fmt.aprintf("Unexpected token, %s", msg))
				return
			}
		case Error.ExpectedClosingSingleQuote:
			{
				log(ERROR, fmt.aprintf("Expected closing `'`, %s", msg))
				return
			}
		case Error.ExpectedClosingDoubleQuote:
			{
				log(ERROR, fmt.aprintf("Expected closing `\"`, %s", msg))
				return
			}
		}
	}

	log(INFO, fmt.aprintf("%s", msg))

	type_record: TypeStorage // builtin + custom types
	elements: ElementStorage // functions
	signals := init_signals() // starts signals with the null signal

	index, result := parse_token_stream(
		test_file,
		&tokens,
		&values,
		&type_record,
		&elements,
		&signals,
	)

	if result != Error.None {

		#partial switch result {

		case Error.UnknownType:
			{
				log(
					ERROR,
					fmt.aprintf(
						"Unknown type `%s`, line %d.",
						values[index],
						positions[index].line,
					),
				)
				return
			}
		case Error.TypeRedeclaration:
			{
				log(
					ERROR,
					fmt.aprintf(
						"Cannot redeclare type, line %d.  '%s' already exists. ",
						positions[index].line,
						values[index],
					),
				)
				return
			}
		case Error.FunctionRedeclaration:
			{
				log(
					ERROR,
					fmt.aprintf(
						"Cannot redeclare function, line %d.  '%s' already exists. ",
						positions[index].line,
						values[index],
					),
				)
				return
			}
		}
	}

	log(INFO, fmt.aprintf("%v", elements))

	elapsed := time.tick_diff(start, time.tick_now())
	ok := fmt.printfln(
		"       %s Completed %s in:  %.9fs",
		COLOR_BOLD_GREEN,
		COLOR_RESET,
		time.duration_seconds(elapsed),
	)

}
