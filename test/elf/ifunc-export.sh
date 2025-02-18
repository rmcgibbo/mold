#!/bin/bash
export LANG=
set -e
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t="$(pwd)/out/test/elf/$testname"
mkdir -p "$t"

# Skip if libc is musl because musl does not support GNU FUNC
echo 'int main() {}' | cc -o "$t"/exe -xc -
ldd "$t"/exe | grep -q ld-musl && { echo OK; exit; }

cat <<EOF | cc -c -fPIC -o "$t"/a.o -xc -
#include <stdio.h>

__attribute__((ifunc("resolve_foobar")))
void foobar(void);

void real_foobar(void) {
  printf("Hello world\n");
}

typedef void Func();

Func *resolve_foobar(void) {
  return real_foobar;
}
EOF

clang -fuse-ld="$mold" -shared -o "$t"/b.so "$t"/a.o
readelf --dyn-syms "$t"/b.so | grep -Pq '(IFUNC|<OS specific>: 10)\s+GLOBAL DEFAULT   \d+ foobar'

echo OK
