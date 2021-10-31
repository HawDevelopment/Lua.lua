Folders:

-   Generator -> Contains files ast, parser, and lexer
-   Versions -> Contains files for each version of the language

To compile (Win64):

-   `nasm -fwin32 test.asm`
-   `gcc -m32 -o test test.obj`

To test (powershell):

-   `Measure-Command { "./test.exe" }`
-   `Measure-Command { lua example.lua }`
