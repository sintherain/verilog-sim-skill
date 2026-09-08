#!/usr/bin/env python3
"""Generate a self-checking Verilog testbench + stimulus/expected memory files.

Given a JSON spec (signal widths, ops with reference expressions), this
generator produces, inside the working directory:

  tb_gen.v           self-checking testbench (reads .mem files, compares,
                     prints PASS/FAIL, calls $fatal on failure)
  stim_<in>.mem      stimulus per input port          (hex, one row / case)
  expected_<out>.mem expected value per output port   (hex, one row / case)

Usage:
    python3 gen_testbench.py --spec spec.json [--workdir .] [--out tb_gen.v]
                             [--cases-per-op 18] [--top tb_gen]

Spec example (spec.json):
{
  "module": "alu",
  "inputs":  {"a": 4, "b": 4, "sel": 3},
  "outputs": {"f": 4, "cn_4": 1},
  "port_map": {},
  "ops": [
    {"name": "add", "sel": 0, "outputs": {"f": "(a + b) & mask", "cn_4": "(a + b) > mask"}},
    {"name": "sub", "sel": 1, "outputs": {"f": "(a - b) & mask", "cn_4": "a < b"}}
  ],
  "cases_per_op": 18,
  "delay": 1,
  "seed": 42,
  "sel_invert": false
}

Reference expressions may use: a, b, width, mask, max, the binary operators
(+ - * / // % & | ^ << >>), unary (- + ~), comparisons (< > <= >= == !=),
boolean operators (and/or/not) and the conditional expression (x if c else y).
They are parsed with an AST allowlist — no calls, no attributes.
"""

import ast
import json
import os
import random
import sys

BIN_OPS = {
    ast.Add: "+", ast.Sub: "-", ast.Mult: "*", ast.Div: "/", ast.FloorDiv: "//",
    ast.Mod: "%", ast.BitAnd: "&", ast.BitOr: "|", ast.BitXor: "^",
    ast.LShift: "<<", ast.RShift: ">>",
}
UN_OPS = {ast.USub: "-", ast.UAdd: "+", ast.Invert: "~", ast.Not: "not"}
CMP_OPS = {
    ast.Eq: "==", ast.NotEq: "!=", ast.Lt: "<", ast.LtE: "<=",
    ast.Gt: ">", ast.GtE: ">=",
}


def eval_expr(expr, env):
    """Evaluate a small, safe arithmetic/boolean expression."""
    tree = ast.parse(expr, mode="eval")

    def ev(node):
        if isinstance(node, ast.Expression):
            return ev(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, bool)):
            return int(node.value) if isinstance(node.value, bool) else node.value
        if isinstance(node, ast.Name):
            if node.id not in env:
                raise ValueError(f"unknown name '{node.id}' in {expr!r}")
            return env[node.id]
        if isinstance(node, ast.BinOp) and type(node.op) in BIN_OPS:
            l, r = ev(node.left), ev(node.right)
            op = BIN_OPS[type(node.op)]
            if op == "/":
                return int(l / r) if r else 0
            try:
                return eval(f"({l}) {op} ({r})")
            except ZeroDivisionError:
                return 0
        if isinstance(node, ast.UnaryOp) and type(node.op) in UN_OPS:
            op = UN_OPS[type(node.op)]
            return int(eval(f"{op} ({ev(node.operand)})"))
        if isinstance(node, ast.Compare) and len(node.ops) == 1:
            l = ev(node.left)
            r = ev(node.comparators[0])
            op = CMP_OPS[type(node.ops[0])]
            return int(eval(f"({l}) {op} ({r})"))
        if isinstance(node, ast.BoolOp):
            vals = [ev(v) for v in node.values]
            if isinstance(node.op, ast.And):
                return int(all(vals))
            return int(any(vals))
        if isinstance(node, ast.IfExp):
            return int(ev(node.body) if ev(node.test) else ev(node.orelse))
        raise ValueError(f"unsupported expression node {type(node).__name__} in {expr!r}")

    return int(ev(tree))


def make_cases(width, n, seed):
    """Deterministic case list: boundaries, carry/borrow, zero, negatives…"""
    m = (1 << width) - 1
    base = [
        (0, 0), (0, 1), (1, 0), (1, 1),
        (m, m), (m, 0), (0, m), (m - 1, m), (m, m - 1),
        (m // 2, m // 2), (m // 2, m // 2 + 1), (m // 2 + 1, m // 2),
        (1, m), (m, 1), (m - 2, m - 1), (m - 1, m - 2),
        (max(0, m - 3), max(0, m - 3)), (max(0, m - 3), m),
    ]
    rng = random.Random(seed)
    cases = list(base)
    while len(cases) < n:
        cases.append((rng.randrange(0, m + 1), rng.randrange(0, m + 1)))
    return cases[:n]


def mask_of(w):
    return (1 << w) - 1


def main():
    if "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__)
        return 0
    spec_path = None
    workdir = "."
    out_name = "tb_gen.v"
    top = "tb_gen"
    cases_per_op = None
    argv = sys.argv[1:]
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--spec" and i + 1 < len(argv):
            spec_path = argv[i + 1]; i += 2
        elif a == "--workdir" and i + 1 < len(argv):
            workdir = argv[i + 1]; i += 2
        elif a == "--out" and i + 1 < len(argv):
            out_name = argv[i + 1]; i += 2
        elif a == "--top" and i + 1 < len(argv):
            top = argv[i + 1]; i += 2
        elif a == "--cases-per-op" and i + 1 < len(argv):
            cases_per_op = int(argv[i + 1]); i += 2
        else:
            i += 1
    if not spec_path:
        print("error: --spec <spec.json> required", file=sys.stderr)
        return 2
    with open(spec_path, encoding="utf-8") as f:
        spec = json.load(f)

    module = spec["module"]
    inputs = spec["inputs"]           # name -> width
    outputs = spec["outputs"]         # name -> width
    ops = spec["ops"]
    n = cases_per_op or spec.get("cases_per_op", 18)
    delay = spec.get("delay", 1)
    seed = spec.get("seed", 42)
    sel_invert = spec.get("sel_invert", False)
    port_map = spec.get("port_map", {})   # dut_port -> tb_signal
    width = spec.get("width", max(list(inputs.values()) + list(outputs.values()), default=4))
    env = {"width": width, "mask": mask_of(width), "max": mask_of(width)}
    sel_mask = mask_of(inputs.get("sel", max(1, (max(o["sel"] for o in ops)).bit_length())))

    os.makedirs(workdir, exist_ok=True)
    cases = make_cases(width, n, seed)
    total = n * len(ops)

    # ---- compute stimulus + expected ----
    stim = {name: [] for name in inputs}
    exp = {name: [] for name in outputs}
    for op in ops:
        sel = op["sel"] & sel_mask
        if sel_invert:
            sel = (~sel) & sel_mask
        for (a, b) in cases:
            stim["a"].append(a)
            stim["b"].append(b)
            stim["sel"].append(sel)
            for oname, expr in op.get("outputs", {}).items():
                if oname in outputs:
                    v = eval_expr(expr, dict(env, a=a, b=b))
                    exp[oname].append(v & mask_of(outputs[oname]))

    def fmt(v, w):
        return format(v & mask_of(w), f"0{max(1, (w + 3) // 4)}x")

    for name, w in inputs.items():
        with open(os.path.join(workdir, f"stim_{name}.mem"), "w", encoding="utf-8") as f:
            for v in stim[name]:
                f.write(fmt(v, w) + "\n")
    for name, w in outputs.items():
        with open(os.path.join(workdir, f"expected_{name}.mem"), "w", encoding="utf-8") as f:
            for v in exp[name]:
                f.write(fmt(v, w) + "\n")

    # ---- emit testbench ----
    L = []
    A = L.append
    A("`timescale 1ns/1ps")
    A(f"module {top};")
    A(f"  localparam integer NCASES = {total};")
    A("")
    for name, w in inputs.items():
        A(f"  reg [{w-1}:0] stim_{name} [0:NCASES-1];")
    for name, w in outputs.items():
        A(f"  reg [{w-1}:0] exp_{name}  [0:NCASES-1];")
    A("")
    for name, w in inputs.items():
        A(f"  reg [{w-1}:0] {name};")
    for name, w in outputs.items():
        A(f"  wire [{w-1}:0] {name};")
    A("  integer i, fail;")
    A("")
    # instantiate DUT
    A(f"  {module} dut (")
    parts = []
    for tname, w in inputs.items():
        dport = next((k for k, v in port_map.items() if v == tname), tname)
        parts.append(f"    .{dport}({tname})")
    for tname, w in outputs.items():
        dport = next((k for k, v in port_map.items() if v == tname), tname)
        parts.append(f"    .{dport}({tname})")
    A(",\n".join(parts))
    A("  );")
    A("")
    A("  initial begin")
    for name in inputs:
        A(f'    $readmemh("stim_{name}.mem", stim_{name});')
    for name in outputs:
        A(f'    $readmemh("expected_{name}.mem", exp_{name});')
    A('    $dumpfile("waveform.vcd");')
    A(f"    $dumpvars(0, {top});")
    A("    fail = 0;")
    A("    for (i = 0; i < NCASES; i = i + 1) begin")
    for name in inputs:
        A(f"      {name} = stim_{name}[i];")
    A(f"      #{delay};")
    checks = []
    for name, w in outputs.items():
        checks.append(f"{name} !== exp_{name}[i]")
    A(f"      if ({' || '.join(checks)}) begin")
    args = ", ".join([f"{n}=%h" for n in inputs] + [f"{n}=%h" for n in outputs])
    vals = ", ".join([f"{n}" for n in inputs] + [f"{n}" for n in outputs])
    exp_args = ", ".join([f"exp_{n}=%h" for n in outputs])
    exp_vals = ", ".join([f"exp_{n}[i]" for n in outputs])
    A(f'        $display("FAIL i=%0d {args} | {exp_args}", i, {vals}, {exp_vals});')
    A("        fail = fail + 1;")
    A("      end else begin")
    A(f'        $display("PASS i=%0d {args}", i, {vals});')
    A("      end")
    A("    end")
    A("    if (fail == 0) begin")
    A('      $display("TEST PASSED (%0d cases)", NCASES);')
    A("      $finish;")
    A("    end else begin")
    A('      $fatal(1, "TEST FAILED: %0d of %0d cases", fail, NCASES);')
    A("    end")
    A("  end")
    A("endmodule")
    with open(os.path.join(workdir, out_name), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")

    print(f"generated {os.path.join(workdir, out_name)} ({total} cases, {len(ops)} ops)")
    return 0


if __name__ == "__main__":
    sys.exit(main())