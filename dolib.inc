# Common helpers used by multiple stages.

copy_dir_no_git() {
	mkdir "$2"
	if test -e "$1/.git"
	then
		git -C "$1" archive --format=tar HEAD | tar -C "$2" -x
	else
		tar -C "$1" -cf - . | tar -C "$2" -xf -
	fi
}