package v0compiler
import "core:fmt"



Signals :: struct {
    name: [dynamic]string,
}


init_signals :: proc() -> Signals {
    signals: Signals

    append_elem(&signals.name, "null")

    return signals
}


parse_signal :: proc(
	old_i: int,
	tokens: ^[dynamic]Token,
	values: ^[dynamic]string,
    signals: ^Signals,
) -> (
	int,
	Error,
) {

	// now we are at the token after `signal`
	if tokens[old_i] != Token.Identifier && tokens[old_i] != Token.CurlyBracketOpen {
		return old_i, Error.ExpectedSignalNameOrBlock
	}


    if tokens[old_i] == Token.Identifier {
        for signal in signals.name {
            if signal == values[old_i] {
                return old_i, Error.SignalRedeclaration
            }
        }

        append_elem(&signals.name, values[old_i])
        return old_i, Error.None
    }

    i := old_i + 1
    if tokens[old_i] == Token.CurlyBracketOpen {
        for tokens[i] != Token.CurlyBracketClose {
            if tokens[i] == Token.Newline {
                i += 1
                continue
            }
            for signal in signals.name {
                if signal == values[i] {
                    return i, Error.SignalRedeclaration
                }
            }
            append_elem(&signals.name, values[i])
            i+=1
        }
    }

	i += 1 // to go after the closing curly

	log(INFO, fmt.aprintf("Added signals: ` %v `", signals))

	return i, Error.None
}



// potentially any other functions related to processing/dealing with signals go here

