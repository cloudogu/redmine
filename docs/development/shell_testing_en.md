# Shell testing

You can create and amend bash tests in the `batsTests` directory. The make target `unit-test-shell` will support you with a generalized bash test environment.

```bash
make unit-test-shell
```

In order to write testable shell scripts these aspects should be respected:

## Global environment variable `STARTUP_DIR`

The global environment variable `STARTUP_DIR` will point to the directory where the production scripts (aka: scripts-under-test) reside. Inside the dogu container this is usually `/`. But during testing it is easier to put it somewhere else for permission reasons.

A second reason is that the scripts-under-test source other scripts. Absolute paths will make testing quite hard. Source new scripts like so, in order that the tests will run smoothly:

```bash
source "${STARTUP_DIR}"/util.sh
```

Please note in the above example the shellcheck disablement comment. Because `STARTUP_DIR` is wired into the `Dockerfile` it is considered as global environment variable that will never be found unset (which would soon be followed by errors).

Currently sourcing scripts in a static manner (that is: without dynamic variable in the path) makes shell testing impossible (unless you find a better way to construct the test container)

## General structure of scripts-under-test

It is rather uncommon to run a _scripts-under-test_ like `startup.sh` all on its own. Effective unit testing will most probably turn into a nightmare if no proper script structure is put in place. Because these scripts source each other _AND_ execute code **everything** must be set-up beforehand: global variables, mocks of every single binary being called... and so on. In the end the tests would reside on an end-to-end test level rather than unit test level.

The good news is that testing single functions is possible with these little parts:

1. Use sourcing execution guards
2. Run binaries and logic code only inside functions
3. Source with (dynamic yet fixed-up) environment variables

### Use sourcing execution guards

Make sourcing possible with _sourcing execution guards_ like this:

```bash
# yourscript.sh
function runTheThing() {
  echo "hello world"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runTheThing
fi
```

The `if`-condition below will be executed if the script is executed by calling via the shell but not when sourced:

```bash
$ ./yourscript.sh
hello world
$ source yourscript.sh
$ runTheThing
hello world
$
```

Execution guards work also with parameters:

```bash
# yourscript.sh
function runTheThing() {
  echo "${1} ${2}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runTheThingWithParameters "$@"
fi
```

Note the proper argument passing with `"$@"` which allows for arguments that contain whitespace and such.

```bash
$ ./yourscript.sh hello world
hello world
$ source yourscript.sh
$ runTheThing hello bash
hello bash
$
```

### Run binaries and logic code only inside functions

Environment variables and constants are okay, but once logic runs outside a function it will be executed during script sourcing.

### Source with (dynamic yet fixed-up) environment variables

Shellcheck basically says this is a no-no. Anyhow, unless the test container allows for  appropriate script paths there is hardly a way around it:

```bash
sourcingExitCode=0
# shellcheck disable=SC1090
source "${STARTUP_DIR}"/util.sh || sourcingExitCode=$?
if [[ ${sourcingExitCode} -ne 0 ]]; then
  echo "ERROR: An error occurred while sourcing /util.sh."
fi
```

At least make sure that the variables are properly set into the production (f. i. `Dockerfile`)and test environment (set-up an env var in your test).
