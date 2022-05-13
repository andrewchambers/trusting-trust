set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		files="
			./bin/mescc.scm
			./bin/mescc
			./bin/mes
			./mes/lib/x86-mes/crt1.o
			./mes/lib/x86-mes/libmescc.a
			./mes/lib/x86-mes/libc.a
		"
		redo-ifchange $files
		sha256sum $files > "$3"
	;;
	
	mes-sources.list)
		(
			cd mes
			git ls-tree -r --name-only HEAD . \
				| awk  '{print "./mes/" $0}' \
				| grep -v \
					-e '^./mes/test' \
					-e '^./mes/lib' \
					-e '^./mes/include'
		) > "$3"
	;;

	mes-headers.list)
		(
			cd mes
			git ls-tree -r --name-only HEAD . \
				| grep -e '^include/' \
				| awk  '{print "./mes/" $0}'
		) > "$3"
	;;

	mes-libc-sources.list)
		(
			cd mes/build-aux
			mes_kernel=linux
			mes_cpu=x86
			mes_libc=mes
			compiler=mescc
			set +x
			touch config.sh # needed by configure-lib.
			. ./configure-lib.sh
			printf "%s\n" $libc_tcc_SOURCES | sort
		) | sed 's,^\(.\),./mes/\1,g' > "$3"
	;;

	nyacc-sources.list)
		(
			cd nyacc
			git ls-tree -r --name-only HEAD . \
				| awk  '{print "./nyacc/" $0}'
		) > "$3"
	;;

	bin/mes)
		redo-ifchange ./mes-sources.list ../stage0/all.done
		redo-ifchange $(cat ./mes-sources.list)
		cd mes
		env -i \
			PATH="$PWD/../../stage0/bin" \
			ARCH=x86 \
			kaem --strict --verbose --file kaem.run
		cd ..
		chmod +x ./mes/bin/mes
		cp ./mes/bin/mes "$3"
	;;

	bin/mescc.scm)
		redo-ifchange ./mes/scripts/mescc.scm.in
		sed \
			-e "s,@BASH@,/bin/sh,g" \
			-e "s,@prefix@,$PWD/mes,g" \
			-e "s,@guile_site_dir@,$PWD/mes/module:$PWD/nyacc/module,g" \
			-e "s,@bindir@,$PWD/mes/mes/module,g" \
			-e "s,@includedir@,$PWD/mes/include,g" \
			-e "s,@libdir@,$PWD/mes/lib,g" \
			-e "s,@guile_site_ccache_dir@,/tmp/,g" \
			-e "s,@mes_cpu@,x86,g" \
			-e "s,@mes_kernel@,linux,g" \
			./mes/scripts/mescc.scm.in > "$3"
	;;

	bin/mescc)
		redo-ifchange mes-sources.list nyacc-sources.list  ../stage0/all.done
		redo-ifchange $(cat mes-sources.list nyacc-sources.list)
		sed \
			-e "s,@BASH@,/bin/sh,g" \
			-e "s,@prefix@,$PWD/mes,g" \
			-e "s,@guile_site_dir@,$PWD/mes/module:$PWD/nyacc/module,g" \
			-e "s,@bindir@,$PWD/mes/mes/module,g" \
			-e "s,@includedir@,$PWD/mes/include,g" \
			-e "s,@libdir@,$PWD/mes/lib,g" \
			-e "s,@guile_site_ccache_dir@,/tmp/,g" \
			./mes/scripts/mescc.in > "$3"
		chmod +x "$3"
		# Include a timestamp to alter hash when sources change.
		echo "# generated on $(date)" >> "$3"
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

	mes/lib/x86-mes/libmescc.s)
		asmfiles="
			./mes/lib/linux/x86-mes-mescc/syscall-internal.s
			./mes/lib/linux/x86-mes-mescc/syscall.s
			./mes/lib/x86-mes-mescc/setjmp.s
		"
		redo-ifchange $asmfiles
		cat $asmfiles > "$3"
	;;

	mes/lib/x86-mes/libc.s)
		redo-ifchange mes-libc-sources.list
		asmfiles=$(cat mes-libc-sources.list | sed 's/\.c$/.s/g')
		redo-ifchange $asmfiles
		cat $asmfiles > "$3"
	;;

	*.s)
		cfile="${1%.s}.c"
		redo-ifchange ./bin/mescc mes-headers.list "$cfile"
		redo-ifchange $(cat mes-headers.list)
		env -i PATH="$PWD/../stage0/bin:$PATH" \
			./bin/mescc \
			-I "./mes/lib/include" \
			-S \
			-o "$3" \
			"$cfile"
	;;

	*.o)
		sfile="${1%.o}.s"
		redo-ifchange \
			./bin/mescc \
			"$sfile"
		env -i PATH="$PWD/../stage0/bin:$PATH" \
			./bin/mescc \
			-c \
			-o "$3" \
			"$sfile"
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
