SPHINCS+ using N-way parallel Keccak-f1600
==========================================

Implementation of SPHINCS+ leveraging an N-way parallel Keccak-f1600.
Based on the implementations for N=2 from [official SPHINCS+ repository](https://github.com/sphincs/sphincsplus).

## Usage

To build, run

```
CYCLES={NO,PERF,PMU} WAY={N} CORE={A55,A510,A710,A78,X1,X2} PARAMS=sphincs-shake{f,s}-{128,192,256}{f,s} THASH={robus,simple} make
```

which will build the corresponding benchmark as `./benchmark` and a functional test as `./functest`. 
The underlying N-way parallel Keccak-f1600 implementation
is automatically chosen based on the choice of core and parameter set. To force a specific implementation, overwrite the
environment variables `KECCAK_X_IMPL` and/or `KECCAK_X1_IMPL`.

You may also use

```
python3 make_all.py
```

to generate benchmark binaries for all possible combinations of parameters, stored in [bin/](bin/), and `bench_xN.sh` to
run them.

You may run the functional tests using `qemu` as
```
qemu-aarch64 ./functest
```
## KATs

The NIST-provided [source
code](https://csrc.nist.gov/projects/post-quantum-cryptography/post-quantum-cryptography-standardization/example-files)
can be used to generate Known-Answer-Tests (KATs) as done for example in the [official SPHINCS+
repository](https://github.com/sphincs/sphincsplus/tree/master/shake-a64).

## License

Licensed under MIT; see [LICENSE](LICENSE)
