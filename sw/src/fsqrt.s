.global _start

.text

_start:
li x1, 0x40000000
fmv.w.x f1, x1
fsqrt.s f2, f1

end_loop:
j end_loop
