package v0compiler
import "core:fmt"


INFO :: 0
WARNING :: 1
ERROR :: 2



log :: proc(type: int, message: string) {
    switch type {
    
    case INFO: 
        fmt.printfln("%s [INFO]: %s  %s", COLOR_GREEN, COLOR_RESET, message)

    case WARNING:
        fmt.printfln("%s [WARNING]: %s  %s", COLOR_YELLOW, COLOR_RESET, message)

    case ERROR:
        fmt.printfln("%s [ERROR]: %s  %s", COLOR_RED, COLOR_RESET, message)

    }


}






