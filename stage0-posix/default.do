set -eux
set -o pipefail
exec >&2

case "$1" in
	all.sha256sums)
		redo-ifchange ./sources.list
		redo-ifchange $(cat ./sources.list)
		cd src
		env -i /bin/sh -eu ./kaem.x86
		cd ..
		mkdir -p bin
		for f in $(awk '{print $2}' ./src/x86.answers)
		do
			mv "./src/$f" ./bin
		done
		sha256sum ./bin/* > "$3"
	;;
	sources.list)
		# gather sources once initially.
		find src -type f \
		| grep -v -e '.git' -e ' ' > "$3"
	;;
	*)
		echo "don't know how to build $1"
		exit 1
	;;

esac
