#!/bin/bash
export LANG=
set -e
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t="$(pwd)/out/test/elf/$testname"
mkdir -p "$t"

cat <<EOF | cc -o "$t"/a.o -c -xc -
#include <stdio.h>

int main() {
  printf("Hello world\n");
  return 0;
}
EOF

clang -fuse-ld="$mold" -no-pie -o "$t"/exe "$t"/a.o -Wl,--image-base=0x8000000
"$t"/exe | grep -q 'Hello world'
readelf -W --sections "$t"/exe | grep -Pq '.interp\s+PROGBITS\s+0000000008000...\b'

echo OK
