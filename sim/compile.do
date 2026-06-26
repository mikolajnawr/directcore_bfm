# Create and clean work library
vlib work
clear

# Define path to BFM source files
set BFM_DIR "../aldec_bfm"

# 1. Compile Foundations (Order is critical)
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/AXI_CommonPkg.sv"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/AXI_Interface.sv"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_AlteraBFMWrapperPkg.sv"

# 2. Compile Master BFM Core
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4MasterBFMcore.v"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4MasterBFM.v"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4MasterBFM_wrapper.v"

# 3. Compile Slave BFM Core
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4SlaveBFMcore.v"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4SlaveBFM.v"
vlog -sv +define+Ax_AlteraWrappers "$BFM_DIR/Ax_Axi4SlaveBFM_wrapper.v"

# 4. Compile User Logic (Interpreter and Top)
vlog -sv "../tb/axi_interpreter.sv"
vlog -sv "../tb/tb_top.sv"

echo "--- COMPILATION FINISHED ---"