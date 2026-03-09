# Repository Guidelines

## Project Structure & Module Organization
`beanstalkd` is a small C codebase rooted at the repository top level. Core server code lives in files such as `main.c`, `serv.c`, `prot.c`, `job.c`, and `tube.c`, with shared types and declarations in `dat.h`. Platform-specific code is split into `linux.c`, `darwin.c`, `freebsd.c`, and `sunos.c`. Tests live beside the implementation as `test*.c`. Supporting material is under `doc/` for protocol and manpage sources, `ct/` for the vendored test harness, `adm/` for admin helpers, and `pkg/` for release packaging.

## Build, Test, and Development Commands
Use `make` to build the daemon with the repository’s default warning flags. Use `./beanstalkd -h` to inspect runtime options and `./beanstalkd -VVV` for verbose local debugging. Run `make check` to compile and execute the `ct`-based unit and integration tests; this is the main required verification step. Run `make bench` for benchmark-oriented test runs. Use `make clean` to remove build artifacts. If you update the manpage source in `doc/beanstalkd.ronn`, regenerate docs with `ronn doc/beanstalkd.ronn`.

## Coding Style & Naming Conventions
Follow the existing C99 style and keep changes consistent with nearby code. Use 4-space indentation, opening braces on the next line for functions, and `snake_case` for functions and helpers such as `set_sig_handlers` or `make_server_socket`. Keep shared declarations in `dat.h` unless a narrower scope is clearly better. There is no separate formatter configured; the compiler is the main style gate, with warnings enforced through `Makefile` flags such as `-Wall`, `-Werror`, and `-Wformat=2`.

## Testing Guidelines
Add or update tests in `test*.c` for any behavioral change. New `ct` test functions should follow the `cttest_*` naming pattern. Prefer focused tests that exercise protocol behavior, queue state transitions, and platform-sensitive edge cases. Before opening a PR, run `make check`; CI also runs this on pull requests and non-`master` pushes.

## Commit & Pull Request Guidelines
Keep commits narrowly scoped and write short, imperative subjects, for example `clarify the NOT_FOUND response for delete` or `enable greenstalk tests`. Avoid mixing refactors, whitespace cleanup, and functional changes. Pull requests should explain the problem, the fix, and the validation performed. Link related issues when relevant, and discuss large or feature-level changes before implementation because the project prioritizes stability over new functionality.
