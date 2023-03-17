SPHINCS+ using 2-way parallel Keccak-f1600
==========================================

Implementation of SPHINCS+ based on 2-way parallel Keccak-f1600 from [official SPHINCS+
repository](https://github.com/sphincs/sphincsplus).

## Usage

To build, run

```
KECCAK_X2_IMPL={C,BAS,COTHANV8} CYCLES={NO,PERF,PMU} CORE={A55,A510,A78,A710,X1,X2} THASH={robust,simple} PARAMS=sphincs-shake{f,s}-{128,192,256}{f,s} make
```

which will generate the `./benchmark` binary.

You may also use

```
python3 make_all.py
```

to generate benchmark binaries for all possible combinations of parameters, stored in [bin/](bin/), and `bench_x2.sh` to
run them.

## KATs

The NIST-provided [source
code](https://csrc.nist.gov/projects/post-quantum-cryptography/post-quantum-cryptography-standardization/example-files)
can be used to generate Known-Answer-Tests (KATs) as done for example in the [official SPHINCS+
repository](https://github.com/sphincs/sphincsplus/tree/master/shake-a64).

## License

Licensed under CC0 1.0 Universal Public Domain Dedication, see [LICENSE](LICENSE), with
the following exceptions:
* [keccak_f1600_x2/keccakx2_bas.s](keccak_f1600_x2/keccakx2_bas.s): MIT
* [keccak_f1600_x2/keccakx2_cothan.c](keccak_f1600_x2/keccakx2_cothan.c): Apache 2.0
