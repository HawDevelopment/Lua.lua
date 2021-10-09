# Tokens

A list of the diffrent tokens that the lexer can return.

-   `Whitespace`
    The whitespace token WILL NOT be returned.
-   `Newline`
    The newline token WILL NOT be returned.
-   `Comment`
    The comment token WILL NOT be returned.
-   `Identifier`
    A name token. For example `foo` or `bar`.
-   `Number`
    A number token. For example `1` or `2.3`. (NOTE: Hex is not supported yet)
-   `String`
    A string token. For example `"foo"` or `'bar'`. (NOTE: Escape sequences and multiline strings are not supported yet)
-   `Operator`
    An operator token. For example `+` or `-`.
-   `Symbol`
    A symbol token. For example `(` or `)`.
-   `Keyword`
    A keyword token. For example `if` or `else`.
