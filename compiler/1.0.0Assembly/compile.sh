nasm -f elf64 src/compiler.asm -o build/compiler.o
ld build/compiler.o -o build/compiler
./build/compiler $1 $2
nasm -f elf64 src/loader.asm -o build/loader.o
ld build/loader.o -o $3
echo "----------------------------"
./$3
