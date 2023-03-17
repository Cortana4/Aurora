.global _start

.text

_start:
li x1, 255
li x2, 128
add x3, x1, x2

end_loop:
j end_loop
