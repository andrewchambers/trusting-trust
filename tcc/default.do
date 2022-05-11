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
		(
			cd tcc-0.9.26
			git ls-tree -r --name-only HEAD . \
				| grep -v -e tests/ -e win32 \
				| awk  '{print "tcc-0.9.26/" $0}'
		) > "$3"
	;;

	tcc-sources.list)
		(
			cd tcc
			git ls-tree -r --name-only HEAD . \
				| grep -v -e tests/ -e win32 \
				| awk  '{print "tcc/" $0}'
		) > "$3"
	;;

	libc-sources.list)
		# simply include crt1.c, its simpler.
		echo ../mescc/mes/lib/linux/x86-mes-gcc/crt1.c > "$3"
		echo ./tcc-0.9.26/lib/libtcc1.c >> "$3"
		(
			cd ../mescc/mes/build-aux
			mes_kernel=linux
			mes_cpu=x86
			mes_libc=mes
			compiler=gcc # actually tcc, but this is needed.
			set +x
			touch config.sh # needed by configure-lib.
			. ./configure-lib.sh
			echo "$libc_tcc_SOURCES"
		) | sed 's,^\(.\),../mescc/mes/\1,g' >> "$3"
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

		export PATH="$PWD/../stage0/bin:$PATH"
		../mescc/bin/mescc \
			-v \
			-I "../mescc/mes/include" \
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
		redo-ifchange libc-sources.list
		redo-ifchange ./bin/tcc-0.9.26-mescc $(cat libc-sources.list)
		rm -rf ./libc-obj
		mkdir ./libc-obj
		for cfile in $(cat libc-sources.list)
		do
			ofile="./libc-obj/$(basename "$cfile" ".c").o"
			file $ofile
			./bin/tcc-0.9.26-mescc \
				-nostdinc \
				-D TCC_TARGET_I386=1 \
				-I ../mescc/mes/include \
				-I ../mescc/mes/include/linux/x86 \
				-c \
				-o "$ofile" \
				"$cfile"
		done
		./bin/tcc-0.9.26-mescc -ar -cr "$3" libc-obj/*
		rm -rf ./libc-obj
	;;

	bin/tcc-0.9.26)
		redo-ifchange \
			./tcc-0.9.26-sources.list \
			./tcc-0.9.26/config.h \
			./bin/tcc-0.9.26-mescc \
			./lib/libc.a
		redo-ifchange $(cat tcc-0.9.26-sources.list)

		./bin/tcc-0.9.26-mescc \
			-v \
			-nostdinc \
			-nostdlib \
			-I "../mescc/mes/include" \
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
			./tcc-sources.list \
			./tcc/config.h \
			./bin/tcc-0.9.26 \
			./lib/libc.a
		redo-ifchange $(cat tcc-sources.list)

		./bin/tcc-0.9.26 \
			-v \
			-nostdinc \
			-nostdlib \
			-I "../mescc/mes/include" \
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
