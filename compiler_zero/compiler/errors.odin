package v0compiler



Error :: enum {
    None,
    ExpectedClosingSingleQuote,
    ExpectedClosingDoubleQuote,
    UnexpectedToken,
    ExpectedIdentifier,
    ExpectedFunctionIdentifier,
    ExpectedTypeIdentifier,
    ExpectedSignalNameOrBlock,
    ExpectedColon,
    ExpectedParen,
    UnknownType,
    TypeRedeclaration,
    FunctionRedeclaration,
    VariableRedeclaration,
    SignalRedeclaration,
    ExpectedColonOrOpeningCurly,
}

// TODO: make an error buffer so that the program doesnt return at every error
// then read the buffer at the end: if not empty the compilation errors and shows the buffer

