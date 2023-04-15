@echo off

if exist bin (
	rmdir /s /q bin
)

if exist objdump (
	rmdir /s /q objdump
)

for %%t in (rv32mi rv32ui rv32um rv32uf) do (

	mkdir bin\%%t
	mkdir objdump\%%t
	
	for %%f in (src\%%t\*.S) do (
		echo building %%f...
		riscv-none-elf-gcc -march=rv32imf_zicsr_zifencei -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Iinclude -Tlink.ld %%f -o bin\%%t\%%~nf.elf
		riscv-none-elf-objdump -d bin\%%t\%%~nf.elf > objdump\%%t\%%~nf.txt
		riscv-none-elf-objcopy -O binary bin\%%t\%%~nf.elf bin\%%t\%%~nf.bin
		..\..\tools\bin2hex bin\%%t\%%~nf.bin -hex bin\%%t\%%~nf.hex
		
		del bin\%%t\%%~nf.elf
		del bin\%%t\%%~nf.bin
	)
)

pause