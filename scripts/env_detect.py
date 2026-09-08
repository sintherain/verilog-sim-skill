#!/usr/bin/env python3
"""Cross-platform HDL tool detection for the verilog-sim skill.

Prints a JSON report with path + version for iverilog, vvp, gtkwave and
verilator (when found), plus install hints for the detected platform.
Exit code: 0 when iverilog + vvp are available, 1 otherwise.

Usage:
    python3 env_detect.py            # JSON report
    python3 env_detect.py --plain    # human-readable lines
"""

import json
import os
import platform
import shutil
import subprocess
import sys

TOOLS = ("iverilog", "vvp", "gtkwave", "verilator")


def _extra_dirs():
    """Platform-specific candidate directories (besides PATH)."""
    conda = os.environ.get("CONDA_PREFIX")
    if platform.system() == "Windows":
        dirs = []
        for c in "CDEFG":                    # MSYS2 may live on any drive
            dirs.append(f"{c}:/msys64/ucrt64/bin")
            dirs.append(f"{c}:/msys64/usr/bin")
        dirs += ["C:/cygwin64/bin", "C:/iverilog/bin"]
        if conda:
            dirs.append(os.path.join(conda, "Scripts"))
    elif platform.system() == "Darwin":
        dirs = ["/opt/homebrew/bin", "/usr/local/bin"]
        if conda:
            dirs.append(os.path.join(conda, "bin"))
    else:  # Linux / BSD
        dirs = ["/usr/local/bin", "/usr/bin"]
        if conda:
            dirs.append(os.path.join(conda, "bin"))
    return dirs


def candidate_paths(name):
    """PATH first, then well-known install dirs; de-duplicated, in order."""
    out = []
    found = shutil.which(name)
    if found:
        out.append(found)
    ext = ".exe" if platform.system() == "Windows" else ""
    for d in _extra_dirs():
        p = os.path.join(d, name + ext)
        if os.path.isfile(p) and os.access(p, os.X_OK):
            out.append(p)
    seen, uniq = set(), []
    for p in out:
        if p not in seen:
            seen.add(p)
            uniq.append(p)
    return uniq


def version_of(path):
    """Best-effort version string of a tool binary."""
    base = os.path.basename(path).lower()
    flag = "--version" if ("gtkwave" in base or "verilator" in base) else "-V"
    try:
        r = subprocess.run([path, flag], capture_output=True, text=True,
                           timeout=10)
        line = (r.stdout or r.stderr or "").strip().splitlines()
        return line[0][:200] if line else ""
    except Exception:
        return ""


def platform_id():
    sysname = platform.system()
    if sysname == "Windows":
        for c in "CDEFG":
            if os.path.exists(f"{c}:/msys64"):
                return "windows-msys2"
        return "windows"
    if sysname == "Darwin":
        return "macos"
    try:
        with open("/etc/os-release", encoding="utf-8") as f:
            for line in f:
                if line.startswith("ID="):
                    return "linux-" + line.split("=", 1)[1].strip('"')
    except Exception:
        pass
    return "linux"


# install hints: (platform_id, tool) -> command line to install the tool
HINTS = {
    ("linux-ubuntu", "iverilog"): "sudo apt install iverilog",
    ("linux-debian", "iverilog"): "sudo apt install iverilog",
    ("linux-arch", "iverilog"): "sudo pacman -S iverilog",
    ("linux-fedora", "iverilog"): "sudo dnf install iverilog",
    ("linux-ubuntu", "gtkwave"): "sudo apt install gtkwave",
    ("linux-debian", "gtkwave"): "sudo apt install gtkwave",
    ("linux-arch", "gtkwave"): "sudo pacman -S gtkwave",
    ("linux-fedora", "gtkwave"): "sudo dnf install gtkwave",
    ("windows-msys2", "iverilog"):
        'PATH="/usr/bin:$PATH" pacman -S --noconfirm mingw-w64-ucrt-x86_64-iverilog',
    ("windows-msys2", "gtkwave"):
        'PATH="/usr/bin:$PATH" pacman -S --noconfirm mingw-w64-ucrt-x86_64-gtkwave',
    ("windows", "iverilog"):
        "install MSYS2 + mingw-w64-ucrt-x86_64-iverilog, or the Win32 iverilog release",
    ("windows", "gtkwave"):
        "install GTKWave for Windows (MSYS2 package, or the standalone build)",
    ("macos", "iverilog"): "brew install icarus-verilog",
    ("macos", "gtkwave"): "brew install --cask gtkwave",
    ("linux", "iverilog"): "install the iverilog package for your distro (apt/dnf/pacman/zypper)",
    ("linux", "gtkwave"): "install the gtkwave package for your distro (apt/dnf/pacman/zypper)",
}


def main():
    plain = "--plain" in sys.argv
    pid = platform_id()
    report = {"platform": pid, "tools": {}, "missing": [], "hints": []}
    fallback_key = "linux" if pid.startswith("linux-") else pid
    for name in TOOLS:
        cands = candidate_paths(name)
        if cands:
            report["tools"][name] = {
                "path": cands[0],
                "candidates": cands[1:3],
                "version": version_of(cands[0]),
            }
        else:
            report["missing"].append(name)
            hint = HINTS.get((pid, name)) or HINTS.get((fallback_key, name))
            report["hints"].append(f"{name}: {hint}" if hint else f"{name}: no hint known")
    ok = all(n in report["tools"] for n in ("iverilog", "vvp"))
    if plain:
        for name in TOOLS:
            info = report["tools"].get(name)
            print(f"{name}: {info['path']} ({info['version']})" if info
                  else f"{name}: NOT FOUND")
        for h in report["hints"]:
            print("install:", h)
    else:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()