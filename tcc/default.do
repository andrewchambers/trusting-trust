set -eux
set -o pipefail
exec >&2


# libc+tcc.a
mescc_lib="obj/mes-m2/lib"
tcc0_asm="
	${mescc_lib}/ctype/islower.s
	${mescc_lib}/ctype/isupper.s
	${mescc_lib}/ctype/tolower.s
	${mescc_lib}/ctype/toupper.s
	${mescc_lib}/mes/abtod.s
	${mescc_lib}/mes/dtoab.s
	${mescc_lib}/mes/search-path.s
	${mescc_lib}/posix/execvp.s
	${mescc_lib}/stdio/fclose.s
	${mescc_lib}/stdio/fdopen.s
	${mescc_lib}/stdio/ferror.s
	${mescc_lib}/stdio/fflush.s
	${mescc_lib}/stdio/fopen.s
	${mescc_lib}/stdio/fprintf.s
	${mescc_lib}/stdio/fread.s
	${mescc_lib}/stdio/fseek.s
	${mescc_lib}/stdio/ftell.s
	${mescc_lib}/stdio/fwrite.s
	${mescc_lib}/stdio/printf.s
	${mescc_lib}/stdio/remove.s
	${mescc_lib}/stdio/snprintf.s
	${mescc_lib}/stdio/sprintf.s
	${mescc_lib}/stdio/sscanf.s
	${mescc_lib}/stdio/vfprintf.s
	${mescc_lib}/stdio/vprintf.s
	${mescc_lib}/stdio/vsnprintf.s
	${mescc_lib}/stdio/vsprintf.s
	${mescc_lib}/stdio/vsscanf.s
	${mescc_lib}/stdlib/calloc.s
	${mescc_lib}/stdlib/qsort.s
	${mescc_lib}/stdlib/strtod.s
	${mescc_lib}/stdlib/strtof.s
	${mescc_lib}/stdlib/strtol.s
	${mescc_lib}/stdlib/strtold.s
	${mescc_lib}/stdlib/strtoll.s
	${mescc_lib}/stdlib/strtoul.s
	${mescc_lib}/stdlib/strtoull.s
	${mescc_lib}/string/memmem.s
	${mescc_lib}/string/strcat.s
	${mescc_lib}/string/strchr.s
	${mescc_lib}/string/strlwr.s
	${mescc_lib}/string/strncpy.s
	${mescc_lib}/string/strrchr.s
	${mescc_lib}/string/strstr.s
	${mescc_lib}/string/strupr.s
	${mescc_lib}/stub/sigaction.s
	${mescc_lib}/stub/ldexp.s
	${mescc_lib}/stub/mprotect.s
	${mescc_lib}/stub/localtime.s
	${mescc_lib}/stub/sigemptyset.s
	${mescc_lib}/x86-mes-mescc/setjmp.s
	${mescc_lib}/linux/close.s
	${mescc_lib}/linux/rmdir.s
	${mescc_lib}/linux/stat.s
	obj/tcc0.s
"

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		mkdir -p ./bin
		redo-ifchange ./bin/tcc
		sha256sum ./bin/* > "$3"
	;;
	
	tcc-sources.list)
		# gather sources once initially.
		find tcc -type f \
		| grep -v \
		  -e '.git' \
		> "$3"
	;;

	tcc/config.h)
		touch "$3"
	;;

	tcc0.s)
		redo-ifchange \
			tcc-sources.list \
			./tcc/config.h \
			../mescc/bin/mescc
		redo-ifchange $(cat tcc-sources.list)

		../mescc/bin/mescc \
			-v \
		    -I "../mescc/mes-m2/lib/include" \
		    -D BOOTSTRAP=1 \
		    -D TCC_TARGET_I386=1 \
		    -D inline= \
		    -D CONFIG_TCCDIR=\"/tcc\" \
		    -D CONFIG_SYSROOT=\"/\" \
		    -D CONFIG_TCC_CRTPREFIX=\"/\" \
		    -D CONFIG_TCC_ELFINTERP=\"/\" \
		    -D CONFIG_TCC_SYSINCLUDEPATHS=\"/include\" \
		    -D TCC_LIBGCC=\"\" \
		    -D CONFIG_TCC_LIBTCC1_MES=0 \
		    -D CONFIG_TCCBOOT=1 \
		    -D CONFIG_TCC_STATIC=1 \
		    -D CONFIG_USE_LIBGCC=1 \
		    -D TCC_MES_LIBC=1 \
		    -D TCC_VERSION=\"0.9.26\" \
		    -D ONE_SOURCE=1 \
		    -S \
		    -o "$3" \
		    ./tcc/tcc.c
	;;

	obj/mes-m2/*.s)
		cfile="$(
			echo "$1" | sed -e 's,\.s$,.c,g' -e's,^obj,../mescc,g'
		)"
		redo-ifchange \
			"$cfile" \
			../mescc/bin/mescc
		../mescc/bin/mescc \
			-v \
			-I "../mescc/mes-m2/lib/include" \
			-S \
			-o "$3" \
			"$cfile"
	;;

	bin/tcc0)
		mkdir -p $(
			for f in $tcc0_asm
			do
				dirname $f
			done | sort -u
		)
		redo-ifchange $tcc0_asm
		exit 1
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
