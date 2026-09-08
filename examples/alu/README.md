# ALU — flagship example

4-bit ALU with 6 operations (`add/sub/and/or/xor/nand`) and a carry/borrow
flag. This example exercises **the whole skill pipeline**: generator → compile
→ simulate → independent VCD validation.

## Run it

```bash
# 1) generate a self-checking testbench (108 cases = 6 ops x 18 cases)
python ../../scripts/gen_testbench.py --spec spec.json \
       --workdir sim_work --out tb_gen.v

# 2) compile + simulate (run from sim_work so the .mem files resolve)
iverilog -g2012 -s tb_gen -o sim.vvp alu.v sim_work/tb_gen.v
(cd sim_work && vvp ../sim.vvp)          # -> TEST PASSED (108 cases)

# 3) independent VCD validation
python ../../scripts/vcd_checker.py sim_work/waveform.vcd \
       --config signals.json --report sim_work/report.md

# 4) open the waveform
bash ../../scripts/gtkwave_open.sh sim_work/waveform.vcd
```

## Files

| File | Purpose |
|------|---------|
| `alu.v` | the design under test |
| `spec.json` | generator config: ports, widths, ops + reference expressions |
| `signals.json` | VCD checker config: display name → hierarchical signal path |
| `tb_gen.v` (generated) | self-checking testbench, never hand-edited |

## Signal paths (GTKWave / checker)

`tb_gen.dut.a`, `tb_gen.dut.b`, `tb_gen.dut.sel`, `tb_gen.dut.f`, `tb_gen.dut.cn_4`