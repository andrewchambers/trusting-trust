# trusting-trust

Mostly trustworthy paths to self hosted linux userspace.

This project contains tidy and well documented build scripts that make few asumptions about
your host operating system.

# Build stages

## Stage 0

This stage builds initial versions of tools we will use to bootstrap the system.

Depdendencies:

- A linux operating system.
- Functioning posix shell.
- Functioning posix utilities.
- A functioning C99 compiler.

With redo:

```
redo ./x86_64-stage0.tar.gz
```

or with plain shell:

```
$ ./bin/do ./x86_64-stage0.tar.gz
```

## Links

- https://www.cs.cmu.edu/~rdriley/487/papers/Thompson_1984_ReflectionsonTrustingTrust.pdf
- https://bootstrappable.org/