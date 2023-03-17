#
# Copyright (c) 2022 Arm Limited
# Copyright (c) 2022 Matthias Kannwischer
# SPDX-License-Identifier: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

#! /usr/bin/env python3

import multiprocessing
import subprocess
import itertools
import shutil
import os
import sys

cores = ["X1", "A78", "A55", "X2", "A710", "A510"]
fns = ['shake']
options = ["f", "s"]
sizes = [128, 192, 256]
thashes = ['robust', 'simple']
implementations = ['x3', 'x4', 'x5']
bindir = "bin/"

def nameFor(fn, opt, size, thash, impl):
    return f"sphincs-{fn}-{size}{opt}-{thash}_{impl}"

def make(fn, opt, size, thash, impl, core, bindir):
    if not os.path.exists(bindir):
        os.mkdir(bindir)

    if core in ["X1", "A78", "A55"]:
        platform = "v8"
    elif core in ["X2", "A710", "A510"]:
        platform ="v84"
    else:
        raise Exception()

    way = impl.replace("x", "")


    name = nameFor(fn, opt, size, thash, impl)
    overrides = [f'PARAMS=sphincs-{fn}-{size}{opt}', 'THASH='+thash, 'CORE='+core, 'PLATFORM='+platform, 'WAY='+way]

    sys.stderr.write(f"Compiling {name} for {core} …\n")
    sys.stderr.flush()

    subprocess.run(["make", "clean"] + overrides,
        stdout=subprocess.DEVNULL, stderr=sys.stderr, check=True)
    subprocess.run(["make"] + overrides,
        stdout=subprocess.DEVNULL, stderr=sys.stderr, check=True)

    shutil.move("benchmark", f"{bindir}/bench_{core}_{name}")

for fn in fns:
    combinations = itertools.product(options, sizes, thashes, implementations, cores)
    for i, (opt, size, thash, impl, core) in enumerate(combinations):
        make(fn, opt, size, thash, impl, core, bindir)
