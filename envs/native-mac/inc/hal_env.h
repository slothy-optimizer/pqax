#ifndef QEMU_V8A_HAL_ENV_H
#define QEMU_V8A_HAL_ENV_H

#define SEP %%

#define ASM_LOAD(dst,symbol) 	\
  adrp dst, symbol@PAGE  %% add dst, dst, symbol@PAGEOFF

#endif /* QEMU_V8A_HAL_ENV_H */
