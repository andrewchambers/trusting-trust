# trusting-trust

An auditable and documented path to a self hosted linux userspace.

# Dependencies

- An x86-64 linux system with a posix shell.
- A small set of posix utilities (to be documented).
- Optionally, an implementation of the 'redo' build tool
  (https://github.com/apenwarr/redo, https://github.com/leahneukirchen/redo-c and http://www.goredo.cypherpunks.ru/ are tested.).

Importantly you do NOT require an existing compiler.

# Building 

First get the source:

From git:

```
$ git clone https://github.com/andrewchambers/trusting-trust
$ cd trusting-trust
git submodule update --init --recursive
```

From a release:

```
To be done...
```

If you have redo installed:

```
$ cd trusting-trust
$ redo -j $(nproc)
```

If you don't have redo installed:

```
$ ./do
```

Because the whole process is a redo build system, you can also build individual targets
by reading each stages `.do` file.

# Stages

## Stage0

This stage builds https://github.com/oriansj/stage0-posix starting from a
tiny hand written auditable elf file. 

This stage contains a macro assembler, a tiny C compiler implemetned in assembly, and other tools used by the mes C compiler in the next stage.

## Mes

This stage builds https://www.gnu.org/software/mes/ using the tools in stage0.
This stage contains a scheme interpreter and also a more sophisticated C compiler implemented in scheme.


## Tiny C compiler

This stage builds a lightly patched version of https://bellard.org/tcc/ using the mes
c compiler and libc. It then uses this tcc to build a simple version of mes libc
for its own use.

Tiny C compiler is useful because it implements an assembler and linker that 
is more compatible with 'proper' compiler tools.

## cproc, qbe and diet-musl

To be done:

This stage builds lightly patched https://sr.ht/~mcf/cproc/ and https://c9x.me/compile/.
The stage then uses this compiler to build a lightly patched version musl-libc dubbed 'diet-musl'.

cproc can then build itself linking against the libc it just built.

It is important to note that cproc is capable of building a gcc 4.7 and binutils.


## Links

- https://www.cs.cmu.edu/~rdriley/487/papers/Thompson_1984_ReflectionsonTrustingTrust.pdf
- https://bootstrappable.org/
- https://github.com/fosslinux/live-bootstrap