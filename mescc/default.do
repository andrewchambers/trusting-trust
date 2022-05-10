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
			mes/lib/x86-mes/crt1.o
			mes/lib/x86-mes/libmescc.a
			mes/lib/x86-mes/libc.a
		"
		redo-ifchange $files
		sha256sum $files > "$3"
	;;
	
	mes-sources.list)
		find mes -type f \
		| grep -v \
			-e '.git' \
			-e '\.redo' \
			-e '^mes/test' \
			-e '^mes/lib' \
			-e '^mes/include' \
			-e '\.a$'
		> "$3"
	;;

	mes-includes.list)
		find mes -type f \
		| grep \
		  -e 'mes/include' \
		> "$3"
	;;

	mes-libc-sources.list)
		find mes/lib -type f -name '*.[csS]' \
		| grep -v \
		  -e 'mes-mescc/' \
		  -e 'tests/' \
		  -e 'freebsd' \
		  -e 'hurd' \
		  -e 'arm' \
		  -e 'gcc' \
		> "$3"
	;;

	nyacc-sources.list)
		find nyacc -type f \
		| grep \
		  -e '.git' \
		  -e '.redo' \
		> "$3"
	;;

	bin/mes)
		redo-ifchange ./mes-sources.list
		redo-ifchange $(cat ./mes-sources.list)
		redo-ifchange ../stage0/all.done
		cd mes
		env -i \
			PATH="$PWD/../../stage0/bin" \
			ARCH=x86 \
			kaem --strict --verbose --file kaem.run
		cd ..
		cp ./mes/bin/mes "$3"
		chmod +x "$3"
	;;

	bin/mescc)
		# Technically we aren't building mescc, but it's useful
		# to be able to depend on bin/mescc and its sources.
		redo-ifchange \
			./bin/mescc.in \
			./bin/mes \
			./nyacc-sources.list
		dephash=$(
			cat ./bin/mes $(cat ./nyacc-sources.list) | sha256sum | awk '{print $1}'
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

	mes/lib/x86-mes/crt1.o)
		redo-ifchange mes/lib/linux/x86-mes-mescc/crt1.o
		cp mes/lib/linux/x86-mes-mescc/crt1.o "$3"
	;;

	mes/lib/x86-mes/libmescc.S)
		asmfiles="
			./mes/lib/linux/x86-mes-mescc/syscall-internal.S
			./mes/lib/linux/x86-mes-mescc/_exit.S
			./mes/lib/linux/x86-mes-mescc/_write.S
			./mes/lib/linux/x86-mes-mescc/syscall.S
			./mes/lib/x86-mes-mescc/setjmp.S
		"
		redo-ifchange $asmfiles
		cat $asmfiles > "$3"
	;;

	mes/lib/x86-mes/libc.S)
		redo-ifchange mes-libc-sources.list
		asmfiles=$(cat mes-libc-sources.list | sed 's/\.c$/.S/g')
		objfiles=$(cat mes-libc-sources.list | sed 's/\.[cS]$/.o/g')
		redo-ifchange $asmfiles
		redo-ifchange $objfiles
		cat $asmfiles > "$3"
	;;

	*.S)
		cfile="${1%.S}.c"
		redo-ifchange mes-includes.list
		redo-ifchange \
			../mescc/bin/mescc \
			$(cat mes-includes.list) \
			"$cfile"
		../mescc/bin/mescc \
			-I "../mescc/mes/lib/include" \
			-S \
			-o "$3" \
			"$cfile"
	;;

	*.o)
		sfile="${1%.o}.S"
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
