.global _start

.text

_start:
li x1, 0x12345678
li x2, 0x000000ff
sw x1, 32(x0)
sb x2, 32(x0)
lw x3, 32(x0)

end_loop:
j end_loop
