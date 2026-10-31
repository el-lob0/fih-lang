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
    UnexpectedComma,
    UnexpectedIdent,
    PartialTypeAnnotation,
    ExpectedExpression,
    ExpectedOperand,
    UndeclaredVarInExpr,
    TooManyExprs,
    ExpectedComma,
    ExpectedColonOrOpeningCurly,
    CannotAnnotateMultipleVars,
    ExpectedTypeAnnotation,
    ExpectedOpeningCurly,
    UndeclaredVarAssignement,
    ExpectedField,
    FieldDeclaration,
    TypeError,
}

// TODO: make an error buffer so that the program doesnt return at every error
// then read the buffer at the end: if not empty the compilation errors and shows the buffer

