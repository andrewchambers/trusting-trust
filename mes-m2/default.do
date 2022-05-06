set -eux
set -o pipefail
exec >&2

case "$1" in

	all.sha256sums)
		mkdir -p ./bin
		redo-ifchange ./bin/mes-m2
	;;
	
	mes-sources.list)
		# gather sources once initially.
		find src -type f \
		| grep -v \
		  -e '.git' \
		  -e '^src/test' \
		  -e '^src/lib' \
		  -e '^src/include' > "$3" \
		> "$3"
	;;

	nyacc-sources.list)
		find nyacc -type f \
		| grep \
		  -e '.git' \
		> "$3"
	;;

	mes-includes.list)
		find src -type f \
		| grep \
		  -e '^src/include' \
		> "$3"
	;;

	bin/mes-m2)
		redo-ifchange ./mes-sources.list
		redo-ifchange $(cat ./mes-sources.list)
		redo-ifchange ../stage0-posix/all.sha256sums
		cd src
		env -i \
			PATH="$PWD/../../stage0-posix/bin" \
			ARCH=x86 \
			kaem --strict --verbose --file kaem.x86
		cd ..
		cp ./src/bin/mes-m2 "$3"
		chmod +x "$3"
	;;

	*.S)
		cfile="$(realpath "${1%.S}.c")"
		out="$(realpath $3)"

		redo-ifchange mes-includes.list \
			nyacc-sources.list
		redo-ifchange \
			$(cat mes-includes.list nyacc-sources.list) \
			../stage0-posix/all.sha256sums \
			./bin/mes-m2 \
			"$cfile"

		cd src
		env -i \
			MES_ARENA=20000000 \
			MES_MAX_ARENA=20000000 \
			MES_STACK=6000000 \
			PATH="$PWD/../../stage0-posix/bin" \
			../bin/mes-m2 \
			-L ../nyacc/module \
			-e main \
			./scripts/mescc.scm \
			-I ./include -S "$cfile" -o "$out"
	;;

	lib/libc+tcc.a)
		redo-ifchange bin/mes-m2
		src="
			ctype/islower.c
			ctype/isupper.c
			ctype/tolower.c
			ctype/toupper.c
			mes/abtod.c
			mes/dtoab.c
			mes/search-path.c
			posix/execvp.c
			stdio/fclose.c
			stdio/fdopen.c
			stdio/ferror.c
			stdio/fflush.c
			stdio/fopen.c
			stdio/fprintf.c
			stdio/fread.c
			stdio/fseek.c
			stdio/ftell.c
			stdio/fwrite.c
			stdio/printf.c
			stdio/remove.c
			stdio/snprintf.c
			stdio/sprintf.c
			stdio/sscanf.c
			stdio/vfprintf.c
			stdio/vprintf.c
			stdio/vsnprintf.c
			stdio/vsprintf.c
			stdio/vsscanf.c
			stdlib/calloc.c
			stdlib/qsort.c
			stdlib/strtod.c
			stdlib/strtof.c
			stdlib/strtol.c
			stdlib/strtold.c
			stdlib/strtoll.c
			stdlib/strtoul.c
			stdlib/strtoull.c
			string/memmem.c
			string/strcat.c
			string/strchr.c
			string/strlwr.c
			string/strncpy.c
			string/strrchr.c
			string/strstr.c
			string/strupr.c
			stub/sigaction.c
			stub/ldexp.c
			stub/mprotect.c
			stub/localtime.c
			stub/sigemptyset.c
			x86-mes-mescc/setjmp.c
			linux/close.c
			linux/rmdir.c
			linux/stat.c
		"
		redo-ifchange $(
			for cfile in $src
			do
				echo "./src/lib/${cfile%.c}.S"
			done
		)
		exit 1
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
