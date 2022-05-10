set -eux
set -o pipefail
exec >&2

case "$1" in
	all)
		redo-ifchange all.done
	;;

	all.done)
		redo-ifchange ./sources.list
		redo-ifchange $(cat ./sources.list)
		cd stage0-posix
		env -i /bin/sh -eu ./kaem.x86
		cd ..
		for f in $(awk '{print $2}' ./stage0-posix/x86.answers)
		do
			cp "./stage0-posix/$f" ./bin
		done
		sha256sum ./bin/* > "$3"
	;;

	sources.list)
		find stage0-posix -type f \
		| grep -v \
			-e '\.git' \
			-e '\.redo' \
			-e ' ' \
		> "$3"
	;;

	*)
		echo "don't know how to build $1"
		exit 1
	;;
esac
