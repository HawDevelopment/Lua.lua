# Lua.lua

Lua interpreter made in Lua.

Current progress:

-   ✔ Lexer
-   ✔ Parser
-   ❌ Full test covrage
-   ⚒ Compiler
-   ❌ Interpreter

# Usage

Use the `run` command to run a Lua script.

```bash
$ lua Lua.lua run <script.lua>
```

Use the `sim` command to run input.

```bash
$ lua Lua.lua sim
> print("Hello, world!")
Hello, world!
```

# Options

-   `--debug` - Enable debug mode.
-   `--print` - Prints output tokens.

# Contributing

### Building:

Update submodules:

```bash
git submodule update --init --recursive
```

Run builder:

-   Windows:

    ```bash
    cd vendor/luamake
    compile/install.bat
    cd ../..
    vendor/luamake/luamake.exe rebuild
    ```

-   Linux And Mac:

    ```bash
    cd vendor/luamake
    ./compile/install.sh
    cd ../..
    vendor/luamake/luamake rebuild
    ```

### Running:

-   Running with lua:
    ```bash
    lua Lua.lua run <script.lua>
    ```
-   Running build version:

    ```bash
    bin/<os>/Lua(.exe if windows) run <script.lua>
    ```

If you want to contribute, please open an issue or pull request.
If you make any changes to the Lexer, Parser or Interpreter, please add the output file of this command to your pull request:

```bash
$ node perf.js
```

### Tests:

Command for running tests (you need to add git submodules):

```bash
lua vendor/lunar/Lunar.lua --directory test ./test/tests/
```
