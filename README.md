[![Core PR Checks](https://github.com/irensaltali/beanstalkd/actions/workflows/prs.yaml/badge.svg)](https://github.com/irensaltali/beanstalkd/actions/workflows/prs.yaml)
[![Client Compatibility](https://github.com/irensaltali/beanstalkd/actions/workflows/test-clients.yaml/badge.svg)](https://github.com/irensaltali/beanstalkd/actions/workflows/test-clients.yaml)

# beanstalkd

Simple and fast general purpose work queue.

This fork is actively maintained at
https://github.com/irensaltali/beanstalkd.

https://beanstalkd.github.io/

See [doc/protocol.txt](doc/protocol.txt)
for details of the network protocol.

Please note that this project is released with a Contributor
Code of Conduct. By participating in this project you agree
to abide by its terms. See CodeOfConduct.txt for details.

## Quick Start

    $ make
    $ ./beanstalkd


also try,

    $ ./beanstalkd -h
    $ ./beanstalkd -VVV
    $ make CFLAGS=-O2
    $ make CC=clang
    $ make check
    $ make install
    $ make install PREFIX=/usr

Requires Linux (2.6.17 or later), Mac OS X, FreeBSD, or Illumos.

Currently beanstalkd is tested with GCC and clang, but it should work
with any compiler that supports C99.

Uses ronn to generate the manual.
See http://github.com/rtomayko/ronn.


## Subdirectories

- `adm`	- files useful for system administrators
- `ct`	- testing tool; vendored from https://github.com/kr/ct
- `doc`	- documentation
- `pkg`	- scripts to make releases


## Tests

Unit tests are in test*.c. See https://github.com/kr/ct for
information on how to write them.
