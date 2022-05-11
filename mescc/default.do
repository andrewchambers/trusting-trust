set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		files="
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
				| awk  '{print "mes/" $0}' \
				| grep -v \
					-e '^mes/test' \
					-e '^mes/lib' \
					-e '^mes/include'
		) > "$3"
	;;

	mes-includes.list)
		(
			cd mes
			git ls-tree -r --name-only HEAD . \
				| awk  '{print "mes/" $0}' \
				| grep -e '^mes/include'
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
			echo "$libc_tcc_SOURCES"
		) | sed 's,^\(.\),mes/\1,g' > "$3"
	;;

	nyacc-sources.list)
		(
			cd nyacc
			git ls-tree -r --name-only HEAD . \
				| awk  '{print "nyacc/" $0}'
		) > "$3"
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
		# Technically we aren't building mescc, but it's useful
		# to be able to depend on bin/mescc and its sources.
		redo-ifchange \
			../stage0/all.done \
			./bin/mes \
			./bin/mescc.scm \
			./mes/scripts/mescc.in \
			./nyacc-sources.list
		# include the hash.

		sed \
			-e "s,@BASH@,/bin/sh,g" \
			-e "s,@prefix@,$PWD/mes,g" \
			-e "s,@guile_site_dir@,$PWD/mes/module:$PWD/nyacc/module,g" \
			-e "s,@bindir@,$PWD/mes/mes/module,g" \
			-e "s,@includedir@,$PWD/mes/include,g" \
			-e "s,@libdir@,$PWD/mes/lib,g" \
			-e "s,@guile_site_ccache_dir@,/tmp/,g" \
			./mes/scripts/mescc.in > "$3"
		# include something so redo stamps change.
		echo "# generated at $(date)" >> "$3"
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
		redo-ifchange mes-includes.list
		redo-ifchange \
			../mescc/bin/mescc \
			$(cat mes-includes.list) \
			"$cfile"
		
		env -i PATH="$PWD/../stage0/bin:$PATH" \
			../mescc/bin/mescc \
			-I "../mescc/mes/lib/include" \
			-S \
			-o "$3" \
			"$cfile"
	;;

	*.o)
		sfile="${1%.o}.s"
		redo-ifchange \
			../mescc/bin/mescc \
			"$sfile"
		env -i PATH="$PWD/../stage0/bin:$PATH" \
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
