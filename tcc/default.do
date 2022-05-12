set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		redo-ifchange \
			./include.done \
			./lib/libc-4.a \
			./lib/crt1-4.o \
			./lib/libtcc1-4.o \
			./bin/tcc-4
		sha256sum $(find ./include ./bin ./lib -type f) > "$3"
	;;

	include.done)
		redo-ifchange ../mescc/mes-headers.list
		redo-ifchange $(printf "../mescc/%s\n" $(cat ../mescc/mes-headers.list))
		for hdr in $(cat ../mescc/mes-headers.list | sed 's,^mes/,,g')
		do
			mkdir -p "$(dirname "$hdr")"
			cp "../mescc/mes/$hdr" "$hdr"
		done
		sha256sum $(find include -type f) > "$3"
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
		# Note: strerror.c seems to be missing from the upstream list.
		# Note: atof.c seems to be missing from the upstream list.
		(
			echo "../mescc/mes/lib/string/strerror.c"
			echo "../mescc/mes/lib/stdlib/atof.c"
			cd ../mescc/mes/build-aux
			mes_kernel=linux
			mes_cpu=x86
			mes_libc=mes
			compiler=gcc # actually tcc, but this is needed.
			set +x
			touch config.sh # needed by configure-lib.
			. ./configure-lib.sh
			echo "$libc_tcc_SOURCES" | sed 's,^\(.\),../mescc/mes/\1,g'
		) | awk '{if (NF) {$1=$1;print}}' | sort >> "$3"
	;;

	tcc*/config.h)
		touch "$3"
	;;

	bin/tcc-*)

		redo-ifchange \
			./include.done \
			./tcc-0.9.26-sources.list \
			./tcc-0.9.26/config.h
		redo-ifchange $(cat tcc-0.9.26-sources.list)

		stage=${1#bin/tcc-}

		if test "$stage" = 0
		then
			CC="../mescc/bin/mescc"
			LIBS=""
			redo-ifchange ../mescc/all.done
			export PATH="$PWD/../stage0/bin:$PATH"
		else
			CC="./bin/tcc-$(($stage-1))"
			LIBS="
				lib/crt1-$(($stage-1)).o
				lib/libtcc1-$(($stage-1)).o
				lib/libc-$(($stage-1)).a
			"
			redo-ifchange $CC $LIBS
		fi
		case $stage in
			0)
				CFLAGS="
					-D BOOTSTRAP=1
					-D HAVE_SETJMP=1
					-D inline=
				"
			;;
			1)
				CFLAGS="
					-nostdlib -nostdinc
					-D BOOTSTRAP=1
					-D HAVE_SETJMP=1
					-D HAVE_BITFIELD=1
					-D HAVE_LONG_LONG_STUB=1
				"
			;;
			2)
				CFLAGS="
					-nostdlib -nostdinc
					-D BOOTSTRAP=1
					-D HAVE_SETJMP=1
					-D HAVE_BITFIELD=1
					-D HAVE_LONG_LONG=1
					-D HAVE_FLOAT_STUBS=1
				"
			;;
			*)
				CFLAGS="
					-nostdlib -nostdinc
					-D BOOTSTRAP=1
					-D HAVE_SETJMP=1
					-D HAVE_BITFIELD=1
					-D HAVE_LONG_LONG=1
					-D HAVE_FLOAT=1
				"
			;;
		esac

		$CC \
			-v \
			-I ./include \
			$CFLAGS \
			-D TCC_TARGET_I386=1 \
			-D CONFIG_TCC_STATIC=1 \
			-D TCC_VERSION=\"0.9.26\" \
			-D ONE_SOURCE=1 \
			-o "$3" \
			./tcc-0.9.26/tcc.c \
			$LIBS
	;;

	lib/crt1-*.o)
		stage="${1#lib/crt1-}"
		stage="${stage%.o}"
		cfile="../mescc/mes/lib/linux/x86-mes-gcc/crt1.c"
		redo-ifchange ./include.done ./bin/tcc-$stage "$cfile"
		./bin/tcc-$stage \
				-nostdinc \
				-I ./include \
				-c \
				-o "$3" \
				"$cfile"

	;;

	lib/libtcc1-*.o)
		stage="${1#lib/libtcc1-}"
		stage="${stage%.o}"
		cfile="./tcc-0.9.26/lib/libtcc1.c"
		redo-ifchange ./include.done ./bin/tcc-$stage "$cfile"
		./bin/tcc-$stage \
				-nostdinc \
				-I ./include \
				-D TCC_TARGET_I386=1 \
				-c \
				-o "$3" \
				"$cfile"
	;;

	lib/libc-*.a)
		stage="${1#lib/libc-}"
		stage="${stage%.a}"
		redo-ifchange ./libc-sources.list ./include.done ./bin/tcc-$stage
		redo-ifchange $(cat libc-sources.list)
		rm -rf ./libc-obj-$stage
		mkdir ./libc-obj-$stage
		for cfile in $(cat libc-sources.list)
		do
			ofile="./libc-obj-$stage/$(basename "$cfile" ".c").o"
			./bin/tcc-$stage \
				-nostdinc \
				-I ./include \
				-I ./include/linux/x86 \
				-c \
				-o "$ofile" \
				"$cfile"
		done
		./bin/tcc-$stage -ar -crs "$3" libc-obj-$stage/*
		rm -rf ./libc-obj-$stage
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
