# sphincs-shake-128f-robust

$ ./benchmark 
Parameters: n = 16, h = 66, d = 22, b = 6, k = 33, w = 16
Running 10 iterations.
thash                avg.        1.22 us (0.00 sec); median          3,150 cycles,      1x:          3,150 cycles
f1600x2              avg.        0.60 us (0.00 sec); median          1,548 cycles,      1x:          1,548 cycles
thashx2              avg.        1.21 us (0.00 sec); median          3,139 cycles,      1x:          3,139 cycles
Generating keypair.. avg.     2664.95 us (0.00 sec); median      6,918,351 cycles,      1x:      6,918,351 cycles
  - WOTS pk gen 2x.. avg.      665.72 us (0.00 sec); median        369,609 cycles,      4x:      1,478,436 cycles
Signing..            avg.    61823.89 us (0.06 sec); median         41,652 cycles,      1x:         41,652 cycles
  - FORS signing..   avg.     3234.24 us (0.00 sec); median          2,357 cycles,      1x:          2,357 cycles
  - WOTS pk gen x2.. avg.      665.97 us (0.00 sec); median              0 cycles,     88x:              0 cycles
Verifying..          avg.     4058.85 us (0.00 sec); median          2,574 cycles,      1x:          2,574 cycles
Signature size: 17088 (16.69 KiB)
Public key size: 32 (0.03 KiB)
Secret key size: 64 (0.06 KiB)
