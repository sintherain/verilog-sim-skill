# Counter example

4-bit up counter with enable and async active-low reset. Demonstrates the
race-free **cycle** pattern from `templates/tb_counter.v` (apply inputs
mid-cycle, sample after the update edge, one check per clock).

## Run it

```bash
iverilog -g2012 -s tb -o sim.vvp counter.v tb_counter.v
vvp sim.vvp                        # -> TEST PASSED
bash ../../scripts/gtkwave_open.sh waveform.vcd
```