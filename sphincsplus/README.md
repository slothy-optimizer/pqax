# SPHINCS+ on AArch64

## Overview

This directory contains source code, scripts and benchmarks accompanying the paper "Hybrid scalar/vector
implementations for Keccak on AArch64" by Becker and Kannwischer.

## Structure

* [sphincsplus-keccakx2](sphincsplus-keccakx2) hosts the implementation of SPHINCS+ from the [official SPHINCS+
repository](https://github.com/sphincs/sphincsplus) making use of $2$-way parallel Keccak-f1600 implementations.

* [sphincsplus-keccakxN](sphincsplus-keccakxN) is a derived implementation of SPHINCS+ which can leverage general N-way
parallel Keccak-f1600 implementations, and is used with the AArch64 assembly implementations found in [this
repository](../asm/manual/keccak_1600).


## License

See [sphincsplus-keccakx2/LICENSE](sphincsplus-keccakx2/LICENSE) and [sphincsplus-keccakxN/LICENSE](sphincsplus-keccakxN/LICENSE)
