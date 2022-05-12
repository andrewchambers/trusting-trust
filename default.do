set -eu
exec >&2
case "$1" in
	all)
		redo-ifchange cproc/all.done
	;;

	clean)
		git clean -fxd
		git submodule foreach git clean -fxd
	;;
esac