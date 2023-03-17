#! /usr/bin/env python3

## MIT License
##
## Copyright (c) 2021 Arm Limited
## Copyright (c) 2022 Matthias Kannwischer
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##

import os
from re import S
import argparse
import itertools

parser = argparse.ArgumentParser()

parser.add_argument("-f","--fmt", choices=["tex", "md"], required=True)
parser.add_argument("-a", "--all", default=False, action="store_true")
args = parser.parse_args()

markdown = args.fmt == "md"
all = args.all

def parse(line):
    cycles = line.split(":")[-1]
    cycles = cycles.replace("cycles", "").replace(",", "")
    cycles = int(cycles)
    return cycles



def fmts(value):
    return f"({value:.2f} $\\times$)"

def getBench(bench_dir, variant=None):
    d = {}

    # parse benchmark files
    for paramset in os.listdir(bench_dir):
        parts = paramset.split("_")
        paramname = parts[0]
        if len(parts) > 1 and parts[1] != variant and variant is not None:
            continue

        with open(os.path.join(bench_dir, paramset)) as f:
            lines = f.readlines()

        keypair = None
        sign = None
        verify = None

        for line in lines:
            if "Generating keypair" in line:
                keypair = parse(line)

            if "Signing.." in line:
                sign = parse(line)

            if "Verifying.." in line:
                verify = parse(line)
        d[paramname] = {
            "k" : keypair,
            "s" : sign,
            "v" : verify
        }
    return d


platforms = ["X1", "A78", "A55", "X2", "A710", "A510"]
baselineVariants = ["C", "COTHANV8", "BAS"]
optimizedVariants = ["x3", "x4", "x5"]

if markdown:
    implementationNames = {
        "C" : "[C][C]",
        "COTHANV8" : "[Ngu][Ngu]",
        "BAS" : "[Wes][Wes]",
        "x3": "Ours",
        "x4": "Ours",
        "x5": "Ours"
    }

    if all:
        implementationNames["x3"] = "Ours (x3)"
        implementationNames["x4"] = "Ours (x4)"
        implementationNames["x5"] = "Ours (x5)"
else :
    implementationNames = {
        "C" : "C\\cite{XKCP}",
        "COTHANV8" : "\\cite{CothanSHA3}",
        "BAS" : "\\cite{BasSHA3}",
        "x3": "Ours",
        "x4": "Ours",
        "x5": "Ours"
    }


if all:

    options = ["f", "s"]
    sizes = [128, 192, 256]
    thashes = ['simple', 'robust']
    parameterSets = []
    for size, opt, thash in itertools.product(sizes, options,thashes):
        parameterSets.append(f"sphincs-shake-{size}{opt}-{thash}")

else:
    parameterSets = ["sphincs-shake-128f-robust", "sphincs-shake-128s-robust"]

# set to only display one variant in the table
if not all:
    filterVariants = {
        "X1" : "x4",
        "A78" : {
            "sphincs-shake-128f-robust":  "x4",
            "sphincs-shake-128s-robust":  "x5"
        },
        "A55" : "x4",
        "X2"  : {
            "sphincs-shake-128f-robust":  "x4",
            "sphincs-shake-128s-robust":  "x3"
        },
        "A710" : "x4",
        "A510" : "x4"
    }
else:
    filterVariants = None


def getBenchmarksForPlatform(platform):
    baseline = {}


    for baselineVariant in baselineVariants:
        b = getBench(f"sphincsplus-keccakx2/benchmarks_{platform}", baselineVariant)
        if len(b.keys()) > 0:
            baseline[baselineVariant] = b

    optimized = {}
    for optimizedVariant in optimizedVariants:
        d = f"sphincsplus-keccakxN/benchmarks_{platform}"

        if filterVariants is not None and platform in filterVariants and type(filterVariants[platform]) != dict and filterVariants[platform] != optimizedVariant:
            continue


        if os.path.exists(d):
            results = getBench(d, optimizedVariant)


            if filterVariants is not None and platform in filterVariants and type(filterVariants[platform]) == dict:
                filteredResults = {}
                for param in parameterSets:
                    # print(filterVariants[platform])
                    if filterVariants[platform][param] == optimizedVariant:
                        filteredResults[param] = results[param]
            else:
                filteredResults = results


            optimized[optimizedVariant] = filteredResults



    # print(baseline)
    return baseline, optimized



d = {}
for platform in platforms:
    d[platform] = getBenchmarksForPlatform(platform)


first=True

def getFastest(l):
    k = [i['k'] for i in l]
    s = [i['s'] for i in l]
    v = [i['v'] for i in l]

    return {
        "k" : min(k),
        "s" : min(s),
        "v" : min(v)
    }

def speedup(old, new):
    v = old/new

    if v < 1:
        v = ""
    else:
        v = fmts(v)

    return v


if markdown:
    def fmtc(cycles):
        value = f"{round(cycles):,}"
        return value
    def printHeader():
        pass

    def printPlatformStart(platform, first):
        print(f"# Cortex-{platform}")
        print(f"| Parameter set | Implementation | Key Generation | Signing | Verification |")
        print(f"| ------------- | -------------- | -------------- | ------- | ------------ |")


    def printParamStart(paramName, numImplementations):
        pass

    def printParamEnd():
        pass
    def printFooter():
        print()
        print()
        print("[C]: https://github.com/XKCP/XKCP")
        print("[Ngu]: https://github.com/cothan/NEON-SHA3_2x")
        print("[Wes]: https://github.com/bwesterb/armed-keccak")

    def printRow(variant, cycles, fastestBaseline, paramName):
        name = implementationNames[variant]
        print(f"| {paramName} | {name} | {fmtc(cycles['k'])} |  {fmtc(cycles['s'])} | {fmtc(cycles['v'])} |")

else:
    def fmtc(cycles):
        value = f"{round(cycles/1000):,}k"
        value = value.replace(",", "\\,")
        return value
    def printHeader():
        print("\\begin{tabular}{c|c|rr|rr|rr}")
        print("Parameter set & Impl. & \multicolumn{2}{c|}{Key Generation} & \multicolumn{2}{c|}{Signing} & \multicolumn{2}{c|}{Verification}\\\\")
        print("\\hline")

    def printPlatformStart(platform, first):
        if not first:
            print("\\hline\\hline")
        print(f"\multicolumn{{8}}{{c}}{{Cortex-{platform}}}\\\\\\hline")

    def printParamStart(paramName, numImplementations):
        print(f"\multirow{{{numImplementations}}}{{*}}{{{paramName}}}")

    def printParamEnd():
        print("\\cline{2-8}")

    def printFooter():
        print("\\hline")
        print("\\end{tabular}")

    def printRow(variant, cycles, fastestBaseline, paramName):
        name = implementationNames[variant]

        speedupK = speedup(fastestBaseline['k'], cycles['k'])
        speedupS = speedup(fastestBaseline['s'], cycles['s'])
        speedupV = speedup(fastestBaseline['v'], cycles['v'])
        print(f" & {name} & {fmtc(cycles['k'])} & {speedupK} & {fmtc(cycles['s'])} & {speedupS}& {fmtc(cycles['v'])} & {speedupV}  \\\\")


printHeader()
for platform in platforms:
    printPlatformStart(platform, first)
    if first == True:
        first=False
    baseline, optimized = d[platform]

    numImplementations = len(baseline.keys()) + len(optimized.keys())
    for param in parameterSets:

        baselineFastest = getFastest([baseline[baselineVariant][param] for baselineVariant in baselineVariants if baselineVariant in baseline])
        # print(baselineFastest)
        paramName = param.replace("sphincs-shake-", "")
        printParamStart(paramName, numImplementations)
        for baselineVariant in baselineVariants:
            if baselineVariant not in baseline:
                continue
            cycles = baseline[baselineVariant][param]
            printRow(baselineVariant, cycles, baselineFastest, paramName)


        for optimizedVariant in optimizedVariants:
            if optimizedVariant not in optimized or param not in optimized[optimizedVariant]:
                continue
            cycles = optimized[optimizedVariant][param]
            printRow(optimizedVariant, cycles, baselineFastest, paramName)
        printParamEnd()
printFooter()
