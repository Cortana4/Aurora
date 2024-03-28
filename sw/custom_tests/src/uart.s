.global _start

.text

_start:
li x1, 0x10000000
li x2, 0x00000061
sw x2, 0(x1)
lw x3, 16(x1)
sw x2, 32(x0)
lw x4, 32(x0)

end_loop:
j end_loop
