set -x
exec >&2

mkdir -p bin lib
redo-ifchange bin/mes-m2 lib/libc+tcc.a
sha256sum $(find bin lib) > "$3"
