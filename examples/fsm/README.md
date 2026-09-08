# FSM example

Tiny 3-state machine (`IDLE → RUN → DONE → IDLE`) showing the race-free
**step** pattern from `templates/tb_fsm.v` for state machines.

## Run it

```bash
iverilog -g2012 -s tb -o sim.vvp fsm.v tb_fsm.v
vvp sim.vvp                        # -> TEST PASSED
bash ../../scripts/gtkwave_open.sh waveform.vcd
```