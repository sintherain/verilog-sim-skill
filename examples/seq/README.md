# seq_reg example

Width-parameterized enabled register with async reset — the minimal sequential
design for `templates/tb_seq.v` (self-checking, one `cycle()` per clock).

## Run it

```bash
iverilog -g2012 -s tb -o sim.vvp seq_reg.v tb_seq.v
vvp sim.vvp                        # -> TEST PASSED
bash ../../scripts/gtkwave_open.sh waveform.vcd
```