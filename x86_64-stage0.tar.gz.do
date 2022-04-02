exec >&2
set -u
dir="$(mktemp -d)"
trap "rm -rf \"$dir\"" EXIT
startdir="$(pwd)"
out="$(pwd)/$3"

. ./dolib.inc

find "$startdir/src" -type f -not -path '*/\.git/*' -exec redo-ifchange {} +

pushd "$dir"
destdir="$(pwd)/destdir"
mkdir "$destdir"

copy_dir_no_git "$startdir/src/musl" "musl-host"
for d in musl oksh sbase tinycc kernel-headers
do
	copy_dir_no_git "$startdir/src/$d" "$d"
done

cd musl-host
./configure --prefix="$dir/musl"
make -j$(nproc) install

export LDFLAGS="-static"
export CFLAGS="-static -O3"

export PATH="$dir/musl/bin:$PATH"
if test -e "$dir/musl/bin/musl-gcc"
then
  export CC=musl-gcc
elif test -e "$dir/musl/bin/musl-clang"
then
  export CC=musl-clang
else
  echo "failed to install a usable musl wrapper."
  exit 1
fi

cd ../musl
#./configure --prefix=""
#make -j$(nproc) install DESTDIR="$destdir"
cd ../tinycc
./configure \
  --prefix="/" \
  --enable-static \
  --cc="$CC" \
  --config-bcheck=no \
  --config-backtrace=no
make -j$(nproc) x86_64-libtcc1-usegcc=yes 
make install DESTDIR="$destdir"
cd ../oksh
./configure --prefix=""
make -j$(nproc) && make install DESTDIR="$destdir"
ln -s oksh "$destdir/bin/sh"
cd ../sbase
make -j$(nproc) install PREFIX="" DESTDIR="$destdir" CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" 
cd ../kernel-headers
make ARCH=x86_64 prefix= DESTDIR="$destdir" install

popd
tar -C "$destdir" -cf - . | gzip > "$3"
