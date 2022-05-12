set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		redo-ifchange \
			./bin/cproc-qbe-meslibc \
			./bin/qbe-meslibc
		sha256sum ./bin/* > "$3"
	;;

	qbe-headers.list)
		find ./cproc/qbe -name '*.h' > "$3"
	;;

	qbe-meslibc-sources.list)
		find ./cproc/qbe -name '*.c' \
			| grep -v 'tools/' \
			| sort \
			> "$3"
	;;

	cproc-headers.list)
		printf "%s\n" ./cproc/*.h \
			| sort \
			> "$3"
	;;

	cproc-qbe-meslibc-sources.list)
		printf "%s\n" ./meslibc-extra.c ./cproc/*.c \
			| grep -v 'driver.c$' \
			| sort \
			> "$3"
	;;

	bin/cproc-qbe-meslibc)
		redo-ifchange cproc-qbe-meslibc-sources.list cproc-headers.list ../tcc/all.done
		redo-ifchange $(cat cproc-qbe-meslibc-sources.list cproc-headers.list)
		../tcc/bin/tcc-0.9.26 \
			-nostdinc -nostdlib \
			-I../tcc/include \
			-D_Bool=int \
			-Duint_least32_t=uint32_t \
			-Duint_least16_t=uint16_t \
			-DPRIuLEAST16=\"d\" \
			-DPRIuLEAST32=\"d\" \
			-o "$3" \
			$(cat cproc-qbe-meslibc-sources.list) \
			../tcc/lib/crt1.o \
			../tcc/lib/libtcc1.o \
			../tcc/lib/libc.a
	;;

	bin/qbe-meslibc)
		redo-ifchange qbe-meslibc-sources.list qbe-headers.list ../tcc/all.done
		redo-ifchange $(cat qbe-meslibc-sources.list qbe-headers.list)
		../tcc/bin/tcc-0.9.26 \
			-nostdinc -nostdlib \
			-I../tcc/include \
			-DPRId64=\"ld\" \
			-DPRIi64=\"ld\" \
			-DPRIu64=\"lu\" \
			-o "$3" \
			$(cat qbe-meslibc-sources.list) \
			../tcc/lib/libc.a \
			../tcc/lib/crt1.o \
			../tcc/lib/libtcc1.o \
			../tcc/lib/libc.a
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
