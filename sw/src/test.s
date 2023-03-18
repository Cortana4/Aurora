.global _start

.text

_start:
mv x1, x0
li x2, 10

loop:
addi x1, x1, 1
bne x1, x2, loop

end_loop:
j end_loop
