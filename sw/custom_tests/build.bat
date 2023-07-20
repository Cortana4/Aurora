@echo off
set /p FILE="file: "

if exist obj\%FILE%.o del obj\%FILE%.o
if exist bin\%FILE%.elf del bin\%FILE%.elf
if exist bin\%FILE%.bin del bin\%FILE%.bin
if exist bin\%FILE%.coe del bin\%FILE%.coe
if exist bin\%FILE%.mem del bin\%FILE%.mem
if exist objdump\%FILE%.txt del objdump\%FILE%.txt

if not exist obj mkdir obj
if not exist bin mkdir bin
if not exist objdump mkdir objdump

riscv-none-elf-as -march=rv32imf_zicsr_zifencei -o obj\%FILE%.o src\%FILE%.s
riscv-none-elf-ld -Ttext 0x00000000 -o bin\%FILE%.elf obj\%FILE%.o
riscv-none-elf-objdump -d bin\%FILE%.elf > objdump\%FILE%.txt
riscv-none-elf-objcopy -O binary bin\%FILE%.elf bin\%FILE%.bin
..\..\tools\bin2hex bin\%FILE%.bin -coe bin\%FILE%.coe
..\..\tools\bin2hex bin\%FILE%.bin -mem bin\%FILE%.mem

del obj\%FILE%.o
del bin\%FILE%.elf
del bin\%FILE%.bin
rmdir /q obj

pause