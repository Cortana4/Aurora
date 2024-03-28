.global _start

.text

_start:
li x1, 0x11111111
li x2, 0x22222222

mul x3, x1, x2
mulh x4, x1, x2

end_loop:
j end_loop
