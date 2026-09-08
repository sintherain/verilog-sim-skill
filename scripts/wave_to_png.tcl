# Best-effort GTKWave batch render (no GUI interaction, produces wave.png).
#
# usage:
#   gtkwave waveform.vcd -S scripts/wave_to_png.tcl -o wave.png
#
# NOTE: the GTKWave script API is version-dependent. Adjust the signal list to
# your design (hierarchical names as shown by the SST panel). If your build
# has a different script API, adapt the two commands below.
gtkwave::addSignalsFromList {tb_gen.dut.a tb_gen.dut.b tb_gen.dut.sel tb_gen.dut.f tb_gen.dut.cn_4}
gtkwave::/Time/Zoom_Full
gtkwave::/File/WriteImage wave.png
exit