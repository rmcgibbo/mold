#!/bin/bash
export LANG=
set -e
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t="$(pwd)/out/test/elf/$testname"
mkdir -p "$t"

[ "$(uname -m)" = x86_64 ] || { echo skipped; exit; }

echo 'int main() {}' | cc -m32 -o /dev/null -xc - >& /dev/null \
  || { echo skipped; exit; }

cat <<'EOF' | cc -o "$t"/a.o -c -x assembler -m32 -
  .text
  .globl main
main:
  push $.L.str+3
  call printf
  add $4, %esp
  push $.rodata.str1.1+16
  call printf
  add $4, %esp
  xor %eax, %eax
  ret

  .section .rodata.str1.1, "aMS", @progbits, 1
  .string "bar"
.L.str:
  .string "xyzHello"
  .string "foo world\n"
EOF

clang -m32 -fuse-ld="$mold" -static -o "$t"/exe "$t"/a.o
"$t"/exe | grep -q 'Hello world'

echo OK
