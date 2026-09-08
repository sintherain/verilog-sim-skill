#!/usr/bin/env python3
"""Parse a VCD waveform and validate signal values (stdlib only).

Design-agnostic: you describe the signals you care about (VCD hierarchical
names), the checker tracks their values over time, prints a case table and,
optionally, compares against an expected CSV. Exit code is non-zero when any
expectation mismatches.

Usage:
    python3 vcd_checker.py waveform.vcd [options]

Options:
    --config signals.json   (signals, expected, report, time_scale keys)
    --signals A=tb.dut.A,...                 positional names
    --expected expected.csv                  time,<name>=<value>[,...] rows
    --report report.md                       markdown output file
    --sample N                               max table rows to print (default 50)

signals.json example:
  {"signals": {"A": "tb.dut.u_alu.A", "B": "tb.dut.u_alu.B",
               "Sel": "tb.dut.u_alu.Sel", "F": "tb.dut.u_alu.F",
               "Cn_4": "tb.dut.u_alu.Cn_4"},
   "expected": "expected.csv",
   "report": "report.md"}

expected.csv example (one row per check):
  time,A,B,Sel,F,Cn_4
  100,15,15,0,14,1
  or unheaded rows: 100,A=15,B=15,Sel=0,F=14,Cn_4=1
"""

import csv
import json
import re
import sys

VAR_RE = re.compile(r"\$var\s+(\w+)\s+(\d+)\s+(\S+)\s+(\S+)\s*(\[\d+:\d+\])?\s*\$end")
SCOPE_RE = re.compile(r"\$scope\s+(\w+)\s+(\S+)\s*\$end")
TIME_RE = re.compile(r"^#(\d+)\s*$")
SINGLE_RE = re.compile(r"^([01xXzZ])(\S+)\s*$")
VECTOR_RE = re.compile(r"^([bBrRsS])(\S+)\s*(\S+)\s*$")


def parse_vcd(text):
    """Return (timescale, id->(hier_name,size), events[(time,id,value)])."""
    timescale = ""
    variables = {}
    events = []
    scope = []
    time = 0
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        m = SCOPE_RE.match(line)
        if m:
            scope.append(m.group(2))
            i += 1
            continue
        if line.startswith("$upscope"):
            if scope:
                scope.pop()
            i += 1
            continue
        if line.startswith("$enddefinitions"):
            i += 1
            continue
        m = VAR_RE.match(line)
        if m:
            vtype, size, vid, name, rng = m.groups()
            hier = ".".join(scope + [name])
            variables.setdefault(vid, []).append((hier, int(size)))
            i += 1
            continue
        m = TIME_RE.match(line)
        if m:
            time = int(m.group(1))
            i += 1
            continue
        m = SINGLE_RE.match(line)
        if m:
            events.append((time, m.group(2), m.group(1)))
            i += 1
            continue
        m = VECTOR_RE.match(line)
        if m:
            events.append((time, m.group(3), m.group(2)))
            i += 1
            continue
        if line.startswith("$timescale"):
            # iverilog writes the value on the following line(s)
            value = line.replace("$timescale", "").strip()
            j = i + 1
            while j < len(lines) and "$end" not in lines[j]:
                value += " " + lines[j].strip()
                j += 1
            timescale = value.strip()
            i = j + 1
            continue
        i += 1
    return timescale, variables, events


def walk(events, vars_by_name):
    """Build per-name transition lists: name -> [(time, value), ...]."""
    trans = {n: [] for n in vars_by_name}
    for t, vid, val in events:
        hier = vars_by_name.get((vid, "id"))
        if hier is None:
            continue
        name = hier[0] if isinstance(hier, tuple) else hier
        tr = trans.get(name)
        if tr is not None:
            tr.append((t, val))
    return trans


def value_at(trans, t):
    """Last value with transition time <= t, or None."""
    if not trans:
        return None
    if trans[0][0] > t:
        return None
    lo, hi = 0, len(trans) - 1
    # binary search on time
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if trans[mid][0] <= t:
            lo = mid
        else:
            hi = mid - 1
    return trans[lo][1]


def bits_to_value(bits):
    """'1010' -> 10 when all binary; None otherwise (contains x/z)."""
    if bits and all(c in "01" for c in bits):
        return int(bits, 2)
    return None


def human(bits):
    n = bits_to_value(bits)
    return f"{bits} ({n})" if n is not None else bits


def load_signals(args, cfg):
    sigs = {}
    if cfg and isinstance(cfg.get("signals"), dict):
        sigs.update(cfg["signals"])
    s = getattr(args, "signals", None)
    if isinstance(s, dict):
        sigs.update(s)
    elif isinstance(s, str) and s.strip():
        for pair in s.split(","):
            if "=" in pair:
                a, b = pair.split("=", 1)
                sigs[a.strip()] = b.strip()
            else:
                sigs[pair.strip()] = pair.strip()
    return sigs


def main():
    if len(sys.argv) < 2:
        print("usage: vcd_checker.py <waveform.vcd> [--config ...] [--signals ...]", file=sys.stderr)
        return 2
    vcd_path = sys.argv[1]
    cfg = {}
    # lightweight arg parsing (avoid argparse dependency surprises)
    args = type("A", (), {})()
    args.config = None
    args.signals = None
    args.expected = None
    args.report = None
    args.sample = 50
    argv = sys.argv[2:]
    i = 0
    while i < len(argv):
        if argv[i] == "--config" and i + 1 < len(argv):
            args.config = argv[i + 1]; i += 2
        elif argv[i] == "--signals" and i + 1 < len(argv):
            args.signals = argv[i + 1]; i += 2
        elif argv[i] == "--expected" and i + 1 < len(argv):
            args.expected = argv[i + 1]; i += 2
        elif argv[i] == "--report" and i + 1 < len(argv):
            args.report = argv[i + 1]; i += 2
        elif argv[i] == "--sample" and i + 1 < len(argv):
            args.sample = int(argv[i + 1]); i += 2
        else:
            i += 1
    if args.config:
        try:
            with open(args.config, encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception as e:
            print(f"cannot load config {args.config}: {e}", file=sys.stderr)
            return 2
    for k in ("signals", "expected", "report"):
        v = getattr(args, k)
        if v is None and k in cfg:
            setattr(args, k, cfg[k])
    if args.sample == 50 and "sample" in cfg:
        args.sample = int(cfg["sample"])

    with open(vcd_path, encoding="utf-8", errors="replace") as f:
        text = f.read()
    timescale, variables, events = parse_vcd(text)
    sigs = load_signals(args, cfg)
    if not sigs:
        print("no signals specified; VCD contains:", file=sys.stderr)
        names = {}
        for entries in variables.values():
            for (hier, size) in entries:
                names.setdefault(hier, size)
        for h, s in sorted(names.items()):
            print(f"  {h} [{s}]", file=sys.stderr)
        return 2

    # variables: id -> list of (hier, size). A VCD may declare the same id
    # under several scopes (aliases of the same net); keep every declaration.
    hier2disp = {}
    for display, hier in sigs.items():
        found = False
        for entries in variables.values():
            for (h, s) in entries:
                if h == hier or h.endswith("." + hier):
                    hier2disp[h] = display
                    found = True
        if not found:
            print(f"WARNING: signal not found in VCD: {hier}", file=sys.stderr)
    if not hier2disp:
        print("none of the requested signals exist in the VCD", file=sys.stderr)
        return 2

    # transitions per display name (ids may alias several scopes)
    trans_by_disp = {d: [] for d in set(hier2disp.values())}
    for t, vid, val in events:
        for (h, s) in variables.get(vid, []):
            disp = hier2disp.get(h)
            if disp:
                trans_by_disp[disp].append((t, val))

    # all timestamps where any tracked signal changed (dedup, sorted)
    stamps = sorted({t for tr in trans_by_disp.values() for (t, _) in tr})
    lines = []
    lines.append(f"# VCD check report - {vcd_path}")
    lines.append(f"- timescale: {timescale or 'unknown'}")
    lines.append(f"- signals: { ', '.join(sorted(sigs)) }")
    lines.append(f"- value changes: {len(events)} total")
    lines.append("")
    header = ["time"] + sorted(sigs)
    rows = []
    for t in stamps[: args.sample]:
        row = [str(t)] + [human(value_at(trans_by_disp.get(n, []), t)) for n in sorted(sigs)]
        rows.append(row)

    # optional expected comparison
    fails = []
    checks = 0
    if args.expected:
        try:
            with open(args.expected, encoding="utf-8") as f:
                reader = csv.reader(f)
                for r in reader:
                    if not r or r[0].strip().startswith("#"):
                        continue
                    if len(r) >= 2 and "=" in r[1]:
                        exp_t = int(r[0].strip())
                        pairs = [x.split("=", 1) for x in r[1:]]
                    else:
                        # header row or data row with leading header
                        continue
                    for name, val in pairs:
                        name = name.strip(); val = val.strip()
                        if name not in trans_by_disp:
                            continue
                        checks += 1
                        got = value_at(trans_by_disp[name], exp_t)
                        got_raw = got or ""
                        ok = got_raw == val or (bits_to_value(got_raw or "") == bits_to_value(val) if bits_to_value(val) is not None and bits_to_value(got_raw or "") is not None else False)
                        if not ok:
                            fails.append((exp_t, name, val, got_raw))
        except Exception as e:
            print(f"cannot read expected {args.expected}: {e}", file=sys.stderr)
            return 2

    if rows:
        lines.append("| " + " | ".join(header) + " |")
        lines.append("|" + "|".join(["---"] * len(header)) + "|")
        for r in rows:
            lines.append("| " + " | ".join(r) + " |")
    else:
        lines.append("(no tracked value changes)")

    summary = f"\n## Summary\n- tracked: {len(hier2disp)} signal(s)\n"
    if args.expected:
        summary += f"- checks: {checks}, fails: {len(fails)}\n"
        if fails:
            summary += "\n### Failures\n\n| time | signal | expected | got |\n|---|---|---|---|\n"
            for t, n, e, g in fails[:50]:
                summary += f"| {t} | {n} | {e} | {g} |\n"
    else:
        summary += "- expected file not provided: informational only\n"
    lines.append(summary)

    out = "\n".join(lines)
    print(out)
    if args.report:
        with open(args.report, "w", encoding="utf-8") as f:
            f.write(out + "\n")
        print(f"report written: {args.report}", file=sys.stderr)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())