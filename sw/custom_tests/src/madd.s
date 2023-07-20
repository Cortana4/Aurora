.global _start

.text

_start:
li x1, 0x3fc00000 # 1.5f
li x2, 0x40200000 # 2.5f
li x3, 0x3f000000 # 0.5f

fmv.w.x f1, x1
fmv.w.x f2, x2
fmv.w.x f3, x3

fmadd.s f0, f1, f2, f3

end_loop:
j end_loop
