# 1. Start simulation with PLI libraries and access rights
# Paths are based on your Linux environment
set RIVIERA_BIN "/remote/nas/ahome/minaw/riviera2026.04/bin/Linux64"

vsim -pli $RIVIERA_BIN/libaldecpli.so \
     -pli $RIVIERA_BIN/libAxiBfmPliRiv.so \
     -t 1ps +access +rw directcore_bfm.tb_top

# 2. Add signals to waveform
add wave -position insertpoint sim:/tb_top/master_if/*
add wave -position insertpoint sim:/tb_top/interpreter_i/trans_obj

# 3. Run simulation
run -all

# 4. Zoom fit
wave zoom full