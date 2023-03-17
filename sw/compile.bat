set FILE=test

riscv-none-elf-as -march=rv32imf -o %FILE%.o %FILE%.s
riscv-none-elf-ld -Ttext 0x00000000 -o %FILE% %FILE%.o
riscv-none-elf-objcopy -O binary %FILE%.o  %FILE%.bin
..\tools\bin2coe %FILE%.bin
riscv-none-elf-objdump -d %FILE%
del %FILE%
del %FILE%.o
del %FILE%.bin
pause