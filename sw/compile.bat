@echo off
set /p FILE="file: "

riscv-none-elf-as -march=rv32imf -o bin\%FILE%.o src\%FILE%.s
riscv-none-elf-ld -Ttext 0x00000000 -o bin\%FILE% bin\%FILE%.o
riscv-none-elf-objcopy -O binary bin\%FILE%.o  bin\%FILE%.bin
..\tools\bin2coe bin\%FILE%.bin
riscv-none-elf-objdump -d bin\%FILE%
del bin\%FILE%
del bin\%FILE%.o
del bin\%FILE%.bin
pause