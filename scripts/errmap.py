#!/usr/bin/env python3
"""Match simulator error output against the reference library (errmap.json).

This is the programmatic half of docs/troubleshooting.md: feed it the output
of iverilog / vvp / verilator (with errors, warnings, FAIL lines) and it lists
the matching entries (root cause + fix + source) instead of making the agent
search a document.

Usage:
    iverilog ... 2>&1 | python3 errmap.py              # read stdin
    python3 errmap.py --log sim.log                    # read a log file
    python3 errmap.py --text "error: ..."              # read inline text
    python3 errmap.py --json                           # machine-readable output
    python3 errmap.py --selftest                       # verify all samples match

Exit codes: 0 = at least one entry matched (or selftest passed),
            1 = nothing matched (or selftest failed),
            2 = usage error.
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "errmap.json")


def load_entries():
    with open(DB, encoding="utf-8") as f:
        return json.load(f)["entries"]


def match(text, entries):
    """Return entries whose patterns appear (case-insensitive) in text."""
    low = text.lower()
    hits = []
    for e in entries:
        for pat in e.get("patterns", []):
            if pat.lower() in low:
                hits.append(e)
                break
    return hits


def fmt(hits, machine):
    if machine:
        return json.dumps(hits, ensure_ascii=False, indent=2)
    if not hits:
        return "(no matching entry -- not covered by the reference library)"
    out = []
    n = 0
    for h in hits:
        n += 1
        out.append(f"[{h['id']}] stage: {h['stage']}")
        out.append(f"  root cause: {h['root_cause']}")
        out.append(f"  fix:        {h['fix']}")
        out.append(f"  source:     {h['source']}")
        if h.get("example"):
            out.append(f"  repro:      {h['example']}")
        if n != len(hits):
            out.append("")
    return "\n".join(out)


def read_text_file(path):
    """Windows tools (e.g. PowerShell 2> redirection) may emit UTF-16; try UTF-8
    first, then UTF-16, then the local codepage, before giving up."""
    with open(path, "rb") as f:
        raw = f.read()
    for enc in ("utf-8", "utf-16", "gbk"):
        try:
            return raw.decode(enc)
        except (UnicodeDecodeError, UnicodeError):
            continue
    return raw.decode("utf-8", errors="replace")


def read_text(args):
    for i, a in enumerate(args):
        if a == "--log" and i + 1 < len(args):
            return read_text_file(args[i + 1])
        if a == "--text":
            return " ".join(args[i + 1:])
    if not sys.stdin.isatty():
        return sys.stdin.read()
    return None


def self_test(entries):
    total = 0
    fails = []
    for e in entries:
        s = e.get("sample_error")
        if not s:
            continue
        total += 1
        if not any(p.lower() in s.lower() for p in e.get("patterns", [])):
            fails.append(e["id"])
    print(f"selftest: {total - len(fails)}/{total} sampled entries match their pattern",
          file=sys.stderr)
    if fails:
        print("FAIL:", ", ".join(fails), file=sys.stderr)
        return 1
    return 0


def main():
    args = sys.argv[1:]
    machine = "--json" in args
    entries = load_entries()
    if "--selftest" in args:
        return self_test(entries)
    text = read_text(args)
    if text is None:
        print("usage: pipe tool output, or use --log FILE / --text '...' (--json, --selftest)",
              file=sys.stderr)
        return 2
    hits = match(text, entries)
    print(fmt(hits, machine))
    return 0 if hits else 1


if __name__ == "__main__":
    sys.exit(main())