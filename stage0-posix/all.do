set -x
exec >&2
IFS="
"

cd src
redo-ifchange $(find . -type f -not -name ".git*")
env -i /bin/sh -eu kaem.x86
cd ..
mkdir -p bin
for f in $(awk '{print $2}' src/x86.answers)
do
	mv "src/$f" bin
done
sha256sum bin/* > "$3"