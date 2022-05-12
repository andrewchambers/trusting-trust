set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		redo-ifchange \
			./bin/cproc-qbe-tcc \
		sha256sum ./bin/* > "$3"
	;;

	cproc-headers.list)
		printf "%s\n" ./cproc/*.h \
			| sort \
			> "$3"
	;;

	cproc-qbe-sources.list)
		printf "%s\n" ./mes-libc-extra.c ./cproc/*.c \
			| grep -v 'driver.c$' \
			| sort \
			> "$3"
	;;

	bin/cproc-qbe-tcc)
		redo-ifchange cproc-qbe-sources.list cproc-headers.list ../tcc/all.done
		redo-ifchange $(cat cproc-qbe-sources.list cproc-headers.list)
		../tcc/bin/tcc-0.9.26 \
			-nostdinc -nostdlib \
			-I../tcc/include \
			-D_Bool=int \
			-Duint_least32_t=uint32_t \
			-Duint_least16_t=uint16_t \
			-DPRIuLEAST16=\"d\" \
			-DPRIuLEAST32=\"d\" \
			-o "$3" \
			$(cat cproc-qbe-sources.list) \
			../tcc/lib/libc.a
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
