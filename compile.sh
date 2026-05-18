nasm -f elf64 compiler/1.0.0Assembly/src/compiler.asm -o compiler/1.0.0Assembly/build/compiler.o
ld compiler/1.0.0Assembly/build/compiler.o -o compiler/1.0.0Assembly/build/compiler

./compiler/1.0.0Assembly/build/compiler $1 build/bootx64.efi

echo "----------------------------"

mkdir -p build/iso/EFI/BOOT
cp build/bootx64.efi build/iso/EFI/BOOT/BOOTX64.EFI

cp /usr/share/edk2/x64/OVMF_VARS.4m.fd build/vars.fd

qemu-system-x86_64 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
    -drive if=pflash,format=raw,file=build/vars.fd \
    -drive file=fat:rw:build/iso,format=raw,media=disk \
    -net none
