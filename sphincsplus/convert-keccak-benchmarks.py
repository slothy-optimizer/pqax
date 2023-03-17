#! /usr/bin/env python3

## MIT License
##
## Copyright (c) 2022 Arm Limited
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
import argparse
import re

parser = argparse.ArgumentParser()

parser.add_argument("-f","--fmt", choices=["tex", "md"], required=True)
args = parser.parse_args()

markdown = args.fmt == "md"

with open("keccak-benchmarks.md") as f:
    lines = f.readlines()
categories = { "refScalar" : { "text" : "Reference C",
                               "ref"  : "\\cite{XKCP}",
                               "way"  : 1},
               "ourScalar" : { "text" : "Scalar",
                               "ref"  : "Ours",
                               "way"  : 1},
               "refNeon"   : { "text" : "Neon",
                               "ref"  : "\\cite{CothanSHA3}",
                               "way"  : 2},
               "ourNeon"   : { "text" : "Neon",
                               "ref"  : "Ours",
                               "way"  : 2},
               "refSHA3"   : { "text" : "\\neonsha",
                               "ref"  : "\\cite{BasSHA3}",
                               "way"  : 2},
               "ourSHA3"   : { "text" : "\\neonsha",
                               "ref"  : "Ours",
                               "way"  : 2},
               "hybridNN" : {    "text" : "Neon/\\neonsha",
                                 "ref"  : "Ours",
                                 "way"  : 2},
               "hybridSN3"   : { "text" : "Scalar/Neon/\\neonsha",
                                "ref"  : "Ours",
                                "way"  : 3 },
               "hybridSN8"   : { "text" : "Scalar/Neon",
                                "ref"  : "Ours",
                                "way"  : 4 },
               "hybridSN84"   : { "text" : "Scalar/\\neonsha",
                                "ref"  : "Ours",
                                "way"  : 4 },
               "hybridSN5"   : { "text" : "Scalar/Neon",
                                "ref"  : "Ours",
                                "way"  : 5 },
               "hybridSNN"  : { "text": "Scalar/Neon/\\neonsha",
                                "ref": "Ours",
                                "way": 4 } }

if markdown:
    categories["refScalar"]["ref"] = "[C][C]"
    categories["refNeon"]["ref"]   = "[Ngu][Ngu]"
    categories["refSHA3"]["ref"]   = "[Wes][Wes]"

    for key in categories:
        categories[key]["text"] = categories[key]["text"].replace("\\neonsha", "Neon+SHA-3")


default_functions = { "refScalar" : "keccak_f1600_x1_scalar_C_original",
                      "ourScalar" : "keccak_f1600_x1_scalar_asm_v5",
                      "refNeon"   : "keccak_f1600_x2_neon_C_cothan",
                      "refSHA3"   : "keccak_f1600_x2_bas",
                      "ourSHA3"   : "keccak_f1600_x2_v84a_asm_v1",
                      "ourNeon"   : "keccak_f1600_x2_v84a_asm_v2pp2",
                      "hybridSN8" : "keccak_f1600_x4_hybrid_asm_v3p",
                      "hybridSN84": "keccak_f1600_x4_hybrid_asm_v2",
                      "hybridNN"  : "keccak_f1600_x2_hybrid_asm_v2pp2",
                      "hybridSNN" : "keccak_f1600_x4_hybrid_asm_v4",
                      "hybridSN3" : "keccak_f1600_x3_hybrid_asm_v6",
                      "hybridSN5" : "keccak_f1600_x5_hybrid_asm_v8p" }


exceptions = { "Cortex-A510" : { "ourSHA3" : "keccak_f1600_x2_v84a_asm_v1p0" },
               "Cortex-A55"  : { "ourNeon" : "keccak_f1600_x2_v84a_asm_v2" },
               "Cortex-A710" : { "ourNeon" : "keccak_f1600_x2_v84a_asm_v2pp6",
                                 "hybridNN" : "keccak_f1600_x2_hybrid_asm_v2pp2" } }

def do(platforms, lines, categories=categories):
    linesPerPlatform = {}
    # filter out right lines and group by platform
    start = None
    curPlatform = None
    for idx, line in enumerate(lines):
        if not (line.startswith("#") and "taskset" not in line):
            continue
        # print(line)
        if start != None:
            linesPerPlatform[curPlatform] = lines[start:idx]
            curPlatform = None
            start = None

        for pltfrm in platforms:
            if pltfrm in line:
                curPlatform = pltfrm
                start = idx
                # print(start)

    # print( sorted(list(linesPerPlatform.keys())) )
    assert sorted(list(linesPerPlatform.keys())) == sorted(platforms)

    def parseMedianCC(line):
        line = re.sub(r"^.*\*(.*)\*.*$", r"\1", line)
        return int(line.strip())

    cycles = {}
    for platform, lines in linesPerPlatform.items():
        cycles[platform] = {}
        def get_func_for_platform(plt,cat):
            func = default_functions[cat]
            if plt in exceptions.keys() and \
               cat in exceptions[plt].keys():
                #print(f"Exception on {platform}: use {exceptions[plt][cat]} instead of {func} for {cat}")
                func = exceptions[plt][cat]
            return func
        for category in categories.keys():
            func = get_func_for_platform(platform, category)
            #print(f"{platform}: Use {func} for {category}")
            for line in lines:
                if f"{func})" not in line or "AVGs" not in line:
                    continue
                cc = parseMedianCC(line)
                cycles[platform][category] = cc
                # print(f"{platform}.{category} ({func}): {cc} cycles)")

    if markdown:
        def fmtc(cycles):
            value = f"{cycles}"
            return value
    else:
        def fmtc(cycles):
            value = f"{cycles:,}"
            value = value.replace(",", "\\,")
            return value

    if not markdown:
        header = "&".join([f"\multicolumn{{2}}{{c|}}{{{p}}}" for p in platforms])
        header = "c".join(header.rsplit("c|", 1))
        print(f" Approach & & & {header} \\\\\\hline")
    for category, params in categories.items():
        no_data = True
        cc = []
        way = params["way"]
        txt = params["text"]
        ref = params["ref"]
        for platform in platforms:
            if category in cycles[platform]:
                cyc = cycles[platform][category]
                avg = cyc // way
                if markdown:
                    cc.append(f"{fmtc(cyc)} ({avg})" )
                else:
                    cc.append(f"{fmtc(cyc)}&({avg})" )
                no_data = False
            else:
                if markdown:
                    cc.append("--")
                else:
                    cc.append("-- & ")
        if not no_data:
            if markdown:
                print(f"| {txt} | {ref} | {way}x | " + " | ".join(cc))
            else:
                print(f"{txt} & {ref} & {way}x & " + " & ".join(cc) + "\\\\")

if markdown:
    print("| Approach |   |   |Cortex-X1 | Cortex-A78 | Cortex-A55 |")
    print("| -------- | - | - |--------- | ---------- | -----------|")
    do(["Cortex-X1", "Cortex-A78", "Cortex-A55"], lines)
    print()
    print()
    print("| Approach |   |   | Cortex-X2 | Cortex-A710 | Cortex-A510 |")
    print("| -------- | - | - | --------- | ----------- | ------------|")
    do(["Cortex-X2", "Cortex-A710", "Cortex-A510"], lines)
    print()
    print()
    print("[C]: https://github.com/XKCP/XKCP")
    print("[Ngu]: https://github.com/cothan/NEON-SHA3_2x")
    print("[Wes]: https://github.com/bwesterb/armed-keccak")
else:
    print("\\begin{tabular}{c|c|c|rr|rr|rr}")
    do(["Cortex-X1", "Cortex-A78", "Cortex-A55"], lines)
    print("\\hline\\hline")
    do(["Cortex-X2", "Cortex-A710", "Cortex-A510"], lines)
    print("\\end{tabular}")
