def gen_ubench_name(name,idx):
    return f"{name}_{idx}"

def gen_ubenchmark(name, code, with_padding=True):
    yield f".macro {name}_core"
    for i, c in enumerate(code):
        if "// gap" in c:
            c = "nop"
        yield f"/* {i:02} */ {'':4s}{c}"
    if with_padding:
        yield "padding"
    yield f".endm"
    yield f"make_ubench {name}, nop, {name}_core, nop"

def gen_ubenchmarks(name, code, steps=1):
    lines = len(code)
    for li in range(0,lines,steps):
        yield from gen_ubenchmark(gen_ubench_name(name,li), code[:li])
        yield ""

def gen_c_profiler(name, code, steps=1):
    lines = len(code)
    yield f"ubench_t ubenchs_{name}[] = {{"
    for li in range(0, lines, steps):
        yield f"{'':4s} &ubench_{gen_ubench_name(name,li)},"
    yield "};"
    yield ""
    yield f"char* ubench_{name}_instructions[] = {{"
    for li in range(0, lines, steps):
        yield f"{'':4s} \"{code[li]}\","
    yield "};"
    yield ""
    yield f"const unsigned int num_ubenchs_{name} = {lines};"
    yield ""

def gen_asm_header():
    yield "#include \"ubenchmarks.i\""
    yield "#include \"profiler_macros.i\""
    yield ""

def gen_c_header():
    yield "#include \"profiling.h\""
    yield "#include \"prefix_ubenchs.h\""
    yield ""

def gen_asm(name, code, steps=1):
    yield from gen_asm_header()
    yield from gen_ubenchmarks(name, code, steps=steps)

def gen_c(name, code, steps=1):
    yield from gen_c_header()
    yield from gen_c_profiler(name, code, steps=1)

def gen_header(name, code, steps=1):
    lines = len(code)
    yield "#ifndef PREFIX_UBENCHS_H"
    yield "#define PREFIX_UBENCHS_H"
    yield ""
    for li in range(0, lines, steps):
        yield f"void ubench_{gen_ubench_name(name,li)}(void*,void*,void*,void*,void*);"
    yield ""
    yield f"extern ubench_t ubenchs_{name}[];"
    yield f"extern char* ubench_{name}_instructions[];"
    yield f"extern const unsigned int num_ubenchs_{name};";


    yield "#endif"

infile = open("asm.txt", "r")
lines = infile.read().splitlines()
infile.close()

asm_outfile = open("prefix_ubenchs.s", "w")
asm_outfile.write('\n'.join(gen_asm("prefix", lines)))
asm_outfile.close()

c_outfile = open("profiler.c", "w")
c_outfile.writelines('\n'.join(gen_c("prefix", lines)))
c_outfile.close()

h_outfile = open("prefix_ubenchs.h", "w")
h_outfile.writelines('\n'.join(gen_header("prefix", lines)))
h_outfile.close()
