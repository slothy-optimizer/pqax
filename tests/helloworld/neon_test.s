        .text
        .global neon_test
        .global _neon_test
neon_test:
_neon_test:
        ldr q0, [x0]
        addv h0, v0.8h
        smov w0, v0.h[0]
        strh w0, [x1]
        ret
