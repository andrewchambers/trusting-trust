set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		redo-ifchange \
			./bin/tcc-0.9.26-mescc \
			./bin/tcc-0.9.26 \
			./bin/tcc \
			./lib/libc.a
		sha256sum ./bin/* ./lib/* > "$3"
	;;
	
	tcc-0.9.26-sources.list)
		find tcc-0.9.26 -type f \
		| grep -v \
		  -e '\.git' \
		  -e '\.redo' \
		> "$3"
	;;

	tcc-sources.list)
		find tcc -type f \
		| grep -v \
		  -e '\.git' \
		  -e '\.redo' \
		> "$3"
	;;

	tcc*/config.h)
		touch "$3"
	;;

	bin/tcc-0.9.26-mescc)
		redo-ifchange \
			../mescc/all.done \
			./tcc-0.9.26-sources.list \
			./tcc-0.9.26/config.h

		redo-ifchange $(cat tcc-0.9.26-sources.list)

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
			-o "$3" \
			./tcc-0.9.26/tcc.c
	;;

	lib/libc.a)
		cfiles="
			./tcc/lib/libtcc1.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/crti.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/crtn.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/crt1.c
			../mescc/mes-m2/lib/ctype/isdigit.c
			../mescc/mes-m2/lib/ctype/islower.c
			../mescc/mes-m2/lib/ctype/isnumber.c
			../mescc/mes-m2/lib/ctype/isspace.c
			../mescc/mes-m2/lib/ctype/isupper.c
			../mescc/mes-m2/lib/ctype/isxdigit.c
			../mescc/mes-m2/lib/ctype/tolower.c
			../mescc/mes-m2/lib/ctype/toupper.c
			../mescc/mes-m2/lib/linux/_getcwd.c
			../mescc/mes-m2/lib/linux/_open3.c
			../mescc/mes-m2/lib/linux/_read.c
			../mescc/mes-m2/lib/linux/access.c
			../mescc/mes-m2/lib/linux/brk.c
			../mescc/mes-m2/lib/linux/chmod.c
			../mescc/mes-m2/lib/linux/clock_gettime.c
			../mescc/mes-m2/lib/linux/close.c
			../mescc/mes-m2/lib/linux/dup.c
			../mescc/mes-m2/lib/linux/dup2.c
			../mescc/mes-m2/lib/linux/execve.c
			../mescc/mes-m2/lib/linux/fork.c
			../mescc/mes-m2/lib/linux/fsync.c
			../mescc/mes-m2/lib/linux/getpid.c
			../mescc/mes-m2/lib/linux/gettimeofday.c
			../mescc/mes-m2/lib/linux/ioctl3.c
			../mescc/mes-m2/lib/linux/kill.c
			../mescc/mes-m2/lib/linux/lseek.c
			../mescc/mes-m2/lib/linux/rmdir.c
			../mescc/mes-m2/lib/linux/stat.c
			../mescc/mes-m2/lib/linux/time.c
			../mescc/mes-m2/lib/linux/unlink.c
			../mescc/mes-m2/lib/linux/waitpid.c
			../mescc/mes-m2/lib/mes/__assert_fail.c
			../mescc/mes-m2/lib/mes/__buffered_read.c
			../mescc/mes-m2/lib/mes/__mes_debug.c
			../mescc/mes-m2/lib/mes/abtod.c
			../mescc/mes-m2/lib/mes/abtol.c
			../mescc/mes-m2/lib/mes/assert_msg.c
			../mescc/mes-m2/lib/mes/cast.c
			../mescc/mes-m2/lib/mes/dtoab.c
			../mescc/mes-m2/lib/mes/eputc.c
			../mescc/mes-m2/lib/mes/eputs.c
			../mescc/mes-m2/lib/mes/fdgetc.c
			../mescc/mes-m2/lib/mes/fdputc.c
			../mescc/mes-m2/lib/mes/fdputs.c
			../mescc/mes-m2/lib/mes/fdungetc.c
			../mescc/mes-m2/lib/mes/globals.c
			../mescc/mes-m2/lib/mes/itoa.c
			../mescc/mes-m2/lib/mes/ltoa.c
			../mescc/mes-m2/lib/mes/ltoab.c
			../mescc/mes-m2/lib/mes/mes_open.c
			../mescc/mes-m2/lib/mes/mini-write.c
			../mescc/mes-m2/lib/mes/ntoab.c
			../mescc/mes-m2/lib/mes/oputc.c
			../mescc/mes-m2/lib/mes/oputs.c
			../mescc/mes-m2/lib/mes/search-path.c
			../mescc/mes-m2/lib/mes/ultoa.c
			../mescc/mes-m2/lib/mes/utoa.c
			../mescc/mes-m2/lib/posix/buffered-read.c
			../mescc/mes-m2/lib/posix/execv.c
			../mescc/mes-m2/lib/posix/execvp.c
			../mescc/mes-m2/lib/posix/getcwd.c
			../mescc/mes-m2/lib/posix/getenv.c
			../mescc/mes-m2/lib/posix/isatty.c
			../mescc/mes-m2/lib/posix/open.c
			../mescc/mes-m2/lib/posix/raise.c
			../mescc/mes-m2/lib/posix/setenv.c
			../mescc/mes-m2/lib/posix/wait.c
			../mescc/mes-m2/lib/stdio/fclose.c
			../mescc/mes-m2/lib/stdio/fdopen.c
			../mescc/mes-m2/lib/stdio/ferror.c
			../mescc/mes-m2/lib/stdio/fflush.c
			../mescc/mes-m2/lib/stdio/fgetc.c
			../mescc/mes-m2/lib/stdio/fopen.c
			../mescc/mes-m2/lib/stdio/fprintf.c
			../mescc/mes-m2/lib/stdio/fputc.c
			../mescc/mes-m2/lib/stdio/fputs.c
			../mescc/mes-m2/lib/stdio/fread.c
			../mescc/mes-m2/lib/stdio/fseek.c
			../mescc/mes-m2/lib/stdio/ftell.c
			../mescc/mes-m2/lib/stdio/fwrite.c
			../mescc/mes-m2/lib/stdio/getc.c
			../mescc/mes-m2/lib/stdio/getchar.c
			../mescc/mes-m2/lib/stdio/printf.c
			../mescc/mes-m2/lib/stdio/putc.c
			../mescc/mes-m2/lib/stdio/putchar.c
			../mescc/mes-m2/lib/stdio/remove.c
			../mescc/mes-m2/lib/stdio/snprintf.c
			../mescc/mes-m2/lib/stdio/sprintf.c
			../mescc/mes-m2/lib/stdio/sscanf.c
			../mescc/mes-m2/lib/stdio/ungetc.c
			../mescc/mes-m2/lib/stdio/vfprintf.c
			../mescc/mes-m2/lib/stdio/vprintf.c
			../mescc/mes-m2/lib/stdio/vsnprintf.c
			../mescc/mes-m2/lib/stdio/vsprintf.c
			../mescc/mes-m2/lib/stdio/vsscanf.c
			../mescc/mes-m2/lib/stdlib/atoi.c
			../mescc/mes-m2/lib/stdlib/calloc.c
			../mescc/mes-m2/lib/stdlib/exit.c
			../mescc/mes-m2/lib/stdlib/free.c
			../mescc/mes-m2/lib/stdlib/malloc.c
			../mescc/mes-m2/lib/stdlib/puts.c
			../mescc/mes-m2/lib/stdlib/qsort.c
			../mescc/mes-m2/lib/stdlib/realloc.c
			../mescc/mes-m2/lib/stdlib/strtod.c
			../mescc/mes-m2/lib/stdlib/strtof.c
			../mescc/mes-m2/lib/stdlib/strtol.c
			../mescc/mes-m2/lib/stdlib/strtold.c
			../mescc/mes-m2/lib/stdlib/strtoll.c
			../mescc/mes-m2/lib/stdlib/strtoul.c
			../mescc/mes-m2/lib/stdlib/strtoull.c
			../mescc/mes-m2/lib/string/memchr.c
			../mescc/mes-m2/lib/string/memcmp.c
			../mescc/mes-m2/lib/string/memcpy.c
			../mescc/mes-m2/lib/string/memmem.c
			../mescc/mes-m2/lib/string/memmove.c
			../mescc/mes-m2/lib/string/memset.c
			../mescc/mes-m2/lib/string/strcat.c
			../mescc/mes-m2/lib/string/strchr.c
			../mescc/mes-m2/lib/string/strcmp.c
			../mescc/mes-m2/lib/string/strcpy.c
			../mescc/mes-m2/lib/string/strlen.c
			../mescc/mes-m2/lib/string/strlwr.c
			../mescc/mes-m2/lib/string/strncmp.c
			../mescc/mes-m2/lib/string/strncpy.c
			../mescc/mes-m2/lib/string/strrchr.c
			../mescc/mes-m2/lib/string/strstr.c
			../mescc/mes-m2/lib/string/strupr.c
			../mescc/mes-m2/lib/stub/ldexp.c
			../mescc/mes-m2/lib/stub/localtime.c
			../mescc/mes-m2/lib/stub/mprotect.c
			../mescc/mes-m2/lib/stub/sigaction.c
			../mescc/mes-m2/lib/stub/sigemptyset.c
			../mescc/mes-m2/lib/x86-mes-gcc/setjmp.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/_exit.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/_write.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/syscall.c
			../mescc/mes-m2/lib/linux/x86-mes-gcc/syscall-internal.c
		"
		redo-ifchange ./bin/tcc-0.9.26-mescc $cfiles
		rm -rf ./libc-obj
		mkdir ./libc-obj
		for cfile in $cfiles
		do
			ofile="./libc-obj/$(basename "$cfile" ".c").o"
			file $ofile
			./bin/tcc-0.9.26-mescc \
				-nostdinc \
				-D TCC_TARGET_I386=1 \
				-I ../mescc/mes-m2/include \
				-I ../mescc/mes-m2/include/linux/x86 \
				-c \
				-o "$ofile" \
				"$cfile"
		done
		./bin/tcc-0.9.26-mescc -ar -cr "$3" libc-obj/*
		rm -rf ./libc-obj
	;;

	bin/tcc-0.9.26)
		redo-ifchange \
			tcc-0.9.26-sources.list \
			./tcc-0.9.26/config.h \
			./bin/tcc-0.9.26-mescc
		redo-ifchange $(cat tcc-0.9.26-sources.list)

		./bin/tcc-0.9.26-mescc \
			-v \
			-nostdinc \
			-nostdlib \
			-I "../mescc/mes-m2/include" \
			-D BOOTSTRAP=1 \
			-D HAVE_FLOAT=1 \
			-D HAVE_BITFIELD=1 \
			-D HAVE_LONG_LONG=1 \
			-D HAVE_SETJMP=1 \
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
			-o "$3" \
			./tcc-0.9.26/tcc.c \
			./lib/libc.a
	;;

	bin/tcc)
		redo-ifchange \
			tcc-sources.list \
			./tcc/config.h \
			./bin/tcc-0.9.26
		redo-ifchange $(cat tcc-sources.list)

		./bin/tcc-0.9.26 \
			-v \
			-nostdinc \
			-nostdlib \
			-I "../mescc/mes-m2/include" \
			-D BOOTSTRAP=1 \
			-D HAVE_FLOAT=1 \
			-D HAVE_BITFIELD=1 \
			-D HAVE_LONG_LONG=1 \
			-D HAVE_SETJMP=1 \
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
			-D TCC_VERSION=\"\" \
			-D ONE_SOURCE=1 \
			-o "$3" \
			./tcc/tcc.c \
			./lib/libc.a
	;;



	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
