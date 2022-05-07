set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		mkdir -p ./bin ./lib
		files="
			./bin/mescc
			mes-m2/lib/linux/x86-mes-mescc/crt1.o
			mes-m2/lib/x86-mes/libmescc.a
			mes-m2/lib/x86-mes/libc.a
		"
		redo-ifchange $files
		sha256sum $files > "$3"
	;;
	
	mes-m2-sources.list)
		find mes-m2 -type f \
		| grep -v \
		  -e '.git' \
		  -e '^mes-m2/test' \
		  -e '^mes-m2/lib' \
		  -e '^mes-m2/include' \
		> "$3"
	;;

	mes-m2-includes.list)
		find mes-m2 -type f \
		| grep \
		  -e 'mes-m2/include' \
		> "$3"
	;;

	nyacc-sources.list)
		find nyacc -type f \
		| grep \
		  -e '.git' \
		> "$3"
	;;

	bin/mes-m2)
		redo-ifchange ./mes-m2-sources.list
		redo-ifchange $(cat ./mes-m2-sources.list)
		redo-ifchange ../stage0/all.done
		cd mes-m2
		env -i \
			PATH="$PWD/../../stage0/bin" \
			ARCH=x86 \
			kaem --strict --verbose --file kaem.x86
		cd ..
		cp ./mes-m2/bin/mes-m2 "$3"
		chmod +x "$3"
	;;

	bin/mescc)
		# Technically we aren't building mescc, but it's useful
		# to be able to depend on bin/mescc and its sources.
		redo-ifchange \
			./bin/mescc.in \
			./bin/mes-m2 \
			./nyacc-sources.list
		dephash=$(
			cat ./bin/mes-m2 $(cat ./nyacc-sources.list) | sha256sum | awk '{print $1}'
		)
		# include the hash.
		sed "s/@DEPHASH@/$dephash/g" ./bin/mescc.in > "$3"
		chmod +x "$3"
	;;

	*.a)
		obj="${1%.a}".o
		redo-ifchange "$obj"
		cp "$obj" "$3"
	;;

	mes-m2/lib/x86-mes/libmescc.s)
		asmfiles="
			./mes-m2/lib/linux/x86-mes-mescc/syscall-internal.s
			./mes-m2/lib/linux/x86-mes-mescc/_exit.s
			./mes-m2/lib/linux/x86-mes-mescc/_write.s
			./mes-m2/lib/linux/x86-mes-mescc/syscall.s
			./mes-m2/lib/x86-mes-mescc/setjmp.s
		"
		redo-ifchange $asmfiles
		cat $asmfiles > "$3"
	;;

	mes-m2/lib/x86-mes/libc.s)
		asmfiles="
			./mes-m2/lib/ctype/isdigit.s
			./mes-m2/lib/ctype/islower.s
			./mes-m2/lib/ctype/isnumber.s
			./mes-m2/lib/ctype/isspace.s
			./mes-m2/lib/ctype/isupper.s
			./mes-m2/lib/ctype/isxdigit.s
			./mes-m2/lib/ctype/tolower.s
			./mes-m2/lib/ctype/toupper.s
			./mes-m2/lib/linux/_getcwd.s
			./mes-m2/lib/linux/_open3.s
			./mes-m2/lib/linux/_read.s
			./mes-m2/lib/linux/access.s
			./mes-m2/lib/linux/brk.s
			./mes-m2/lib/linux/chmod.s
			./mes-m2/lib/linux/clock_gettime.s
			./mes-m2/lib/linux/close.s
			./mes-m2/lib/linux/dup.s
			./mes-m2/lib/linux/dup2.s
			./mes-m2/lib/linux/execve.s
			./mes-m2/lib/linux/fork.s
			./mes-m2/lib/linux/fsync.s
			./mes-m2/lib/linux/getpid.s
			./mes-m2/lib/linux/gettimeofday.s
			./mes-m2/lib/linux/ioctl3.s
			./mes-m2/lib/linux/kill.s
			./mes-m2/lib/linux/lseek.s
			./mes-m2/lib/linux/rmdir.s
			./mes-m2/lib/linux/stat.s
			./mes-m2/lib/linux/time.s
			./mes-m2/lib/linux/unlink.s
			./mes-m2/lib/linux/waitpid.s
			./mes-m2/lib/mes/__assert_fail.s
			./mes-m2/lib/mes/__buffered_read.s
			./mes-m2/lib/mes/__mes_debug.s
			./mes-m2/lib/mes/abtod.s
			./mes-m2/lib/mes/abtol.s
			./mes-m2/lib/mes/assert_msg.s
			./mes-m2/lib/mes/cast.s
			./mes-m2/lib/mes/dtoab.s
			./mes-m2/lib/mes/eputc.s
			./mes-m2/lib/mes/eputs.s
			./mes-m2/lib/mes/fdgetc.s
			./mes-m2/lib/mes/fdputc.s
			./mes-m2/lib/mes/fdputs.s
			./mes-m2/lib/mes/fdungetc.s
			./mes-m2/lib/mes/globals.s
			./mes-m2/lib/mes/itoa.s
			./mes-m2/lib/mes/ltoa.s
			./mes-m2/lib/mes/ltoab.s
			./mes-m2/lib/mes/mes_open.s
			./mes-m2/lib/mes/mini-write.s
			./mes-m2/lib/mes/ntoab.s
			./mes-m2/lib/mes/oputc.s
			./mes-m2/lib/mes/oputs.s
			./mes-m2/lib/mes/search-path.s
			./mes-m2/lib/mes/ultoa.s
			./mes-m2/lib/mes/utoa.s
			./mes-m2/lib/posix/buffered-read.s
			./mes-m2/lib/posix/execv.s
			./mes-m2/lib/posix/execvp.s
			./mes-m2/lib/posix/getcwd.s
			./mes-m2/lib/posix/getenv.s
			./mes-m2/lib/posix/isatty.s
			./mes-m2/lib/posix/open.s
			./mes-m2/lib/posix/raise.s
			./mes-m2/lib/posix/setenv.s
			./mes-m2/lib/posix/wait.s
			./mes-m2/lib/posix/write.s
			./mes-m2/lib/stdio/fclose.s
			./mes-m2/lib/stdio/fdopen.s
			./mes-m2/lib/stdio/ferror.s
			./mes-m2/lib/stdio/fflush.s
			./mes-m2/lib/stdio/fgetc.s
			./mes-m2/lib/stdio/fopen.s
			./mes-m2/lib/stdio/fprintf.s
			./mes-m2/lib/stdio/fputc.s
			./mes-m2/lib/stdio/fputs.s
			./mes-m2/lib/stdio/fread.s
			./mes-m2/lib/stdio/fseek.s
			./mes-m2/lib/stdio/ftell.s
			./mes-m2/lib/stdio/fwrite.s
			./mes-m2/lib/stdio/getc.s
			./mes-m2/lib/stdio/getchar.s
			./mes-m2/lib/stdio/printf.s
			./mes-m2/lib/stdio/putc.s
			./mes-m2/lib/stdio/putchar.s
			./mes-m2/lib/stdio/remove.s
			./mes-m2/lib/stdio/snprintf.s
			./mes-m2/lib/stdio/sprintf.s
			./mes-m2/lib/stdio/sscanf.s
			./mes-m2/lib/stdio/ungetc.s
			./mes-m2/lib/stdio/vfprintf.s
			./mes-m2/lib/stdio/vprintf.s
			./mes-m2/lib/stdio/vsnprintf.s
			./mes-m2/lib/stdio/vsprintf.s
			./mes-m2/lib/stdio/vsscanf.s
			./mes-m2/lib/stdlib/atoi.s
			./mes-m2/lib/stdlib/calloc.s
			./mes-m2/lib/stdlib/exit.s
			./mes-m2/lib/stdlib/free.s
			./mes-m2/lib/stdlib/malloc.s
			./mes-m2/lib/stdlib/puts.s
			./mes-m2/lib/stdlib/qsort.s
			./mes-m2/lib/stdlib/realloc.s
			./mes-m2/lib/stdlib/strtod.s
			./mes-m2/lib/stdlib/strtof.s
			./mes-m2/lib/stdlib/strtol.s
			./mes-m2/lib/stdlib/strtold.s
			./mes-m2/lib/stdlib/strtoll.s
			./mes-m2/lib/stdlib/strtoul.s
			./mes-m2/lib/stdlib/strtoull.s
			./mes-m2/lib/string/memchr.s
			./mes-m2/lib/string/memcmp.s
			./mes-m2/lib/string/memcpy.s
			./mes-m2/lib/string/memmem.s
			./mes-m2/lib/string/memmove.s
			./mes-m2/lib/string/memset.s
			./mes-m2/lib/string/strcat.s
			./mes-m2/lib/string/strchr.s
			./mes-m2/lib/string/strcmp.s
			./mes-m2/lib/string/strcpy.s
			./mes-m2/lib/string/strlen.s
			./mes-m2/lib/string/strlwr.s
			./mes-m2/lib/string/strncmp.s
			./mes-m2/lib/string/strncpy.s
			./mes-m2/lib/string/strrchr.s
			./mes-m2/lib/string/strstr.s
			./mes-m2/lib/string/strupr.s
			./mes-m2/lib/stub/ldexp.s
			./mes-m2/lib/stub/localtime.s
			./mes-m2/lib/stub/mprotect.s
			./mes-m2/lib/stub/sigaction.s
			./mes-m2/lib/stub/sigemptyset.s
		"
		redo-ifchange $asmfiles
		cat $asmfiles > "$3"
	;;

	*.s)
		cfile="${1%.s}.c"
		#redo-ifchange mes-m2-includes.list
		#redo-ifchange \
			# XXX
			#../mescc/bin/mescc \
			#$(cat mes-m2-includes.list) \
			#"$cfile"
		../mescc/bin/mescc \
			-I "../mescc/mes-m2/lib/include" \
			-S \
			-o "$3" \
			"$cfile"
	;;

	*.o)
		sfile="${1%.o}.s"
		redo-ifchange \
			../mescc/bin/mescc \
			"$sfile"
		../mescc/bin/mescc \
			-c \
			-o "$3" \
			"$sfile"
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
