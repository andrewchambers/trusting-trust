set -eux
set -o pipefail
exec >&2

case "$1" in

	all.done)
		mkdir -p ./bin
		redo-ifchange ./bin/mes-m2
		sha256sums bin/* > "$3"
	;;
	
	mes-m2-sources.list)
		# gather sources once initially.
		find mes-m2 -type f \
		| grep -v \
		  -e '.git' \
		  -e '^mes-m2/test' \
		  -e '^mes-m2/lib' \
		  -e '^mes-m2/include' > "$3" \
		> "$3"
	;;

	nyacc-sources.list)
		find nyacc -type f \
		| grep \
		  -e '.git' \
		> "$3"
	;;

	mes-m2-includes.list)
		find mes-m2 -type f \
		| grep \
		  -e '^mes-m2/include' \
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

	*.o)
		cfile="$(realpath "${1%.o}.c")"
		out="$(realpath $3)"

		redo-ifchange \
			./mes-includes.list \
			./nyacc-sources.list
		redo-ifchange \
			$(cat mes-includes.list nyacc-sources.list) \
			../stage0-posix/all.sha256sums \
			./bin/mes-m2 \
			"$cfile"

		cd mes-m2
		env -i \
			MES_ARENA=20000000 \
			MES_MAX_ARENA=20000000 \
			MES_STACK=6000000 \
			PATH="$PWD/../../stage0-posix/bin" \
			../bin/mes-m2 \
			-L ../nyacc/module \
			-e main \
			./scripts/mescc.scm \
			-I ./include -c "$cfile" -o "$out"
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
