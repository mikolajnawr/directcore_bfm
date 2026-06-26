`timescale 1ns/1ps
import Ax_AlteraBFMWrapperPkg::*; 

module tb_top;
    // 1. Clock and Reset signals
    bit clk;
    bit rst_n;

    always #5 clk = ~clk; // 100MHz

    // 2. AXI4 Interface Instance (Vendor file: AXI_Interface.sv)
    AXI4_Interface #(32) master_if (.ACLK(clk), .ARESETn(rst_n));

    // 3. Slave Memory (Associative array: maps 32-bit address to 32-bit data)
    logic [31:0] mem [logic [31:0]]; 

    // 4. MASTER BFM Instance
    Ax_Axi4MasterBFM #(
        .DATA_BUS_WIDTH(32),
        .ADDRESS_WIDTH(32),
        .ID_WIDTH(4)
    ) master_core (
        .ACLK(clk), .ARESETn(rst_n),
        .AWID(master_if.AWID), .AWADDR(master_if.AWADDR),
        .AWLEN(master_if.AWLEN), .AWSIZE(master_if.AWSIZE),
        .AWBURST(master_if.AWBURST), .AWLOCK(master_if.AWLOCK),
        .AWCACHE(master_if.AWCACHE), .AWPROT(master_if.AWPROT),
        .AWVALID(master_if.AWVALID), .AWREADY(master_if.AWREADY),
        .WDATA(master_if.WDATA), .WSTRB(master_if.WSTRB),
        .WLAST(master_if.WLAST), .WVALID(master_if.WVALID),
        .WREADY(master_if.WREADY), .BID(master_if.BID),
        .BRESP(master_if.BRESP), .BVALID(master_if.BVALID),
        .BREADY(master_if.BREADY), .ARID(master_if.ARID),
        .ARADDR(master_if.ARADDR), .ARLEN(master_if.ARLEN),
        .ARSIZE(master_if.ARSIZE), .ARBURST(master_if.ARBURST),
        .ARLOCK(master_if.ARLOCK), .ARCACHE(master_if.ARCACHE),
        .ARPROT(master_if.ARPROT), .ARVALID(master_if.ARVALID),
        .ARREADY(master_if.ARREADY), .RID(master_if.RID),
        .RDATA(master_if.RDATA), .RRESP(master_if.RRESP),
        .RLAST(master_if.RLAST), .RVALID(master_if.RVALID),
        .RREADY(master_if.RREADY),
        .AWREGION(), .AWQOS(), .AWUSER(), .ARREGION(), .ARQOS(),
        .ARUSER(), .RUSER(), .WUSER(), .BUSER()
    );

    // 5. SLAVE BFM Instance
    Ax_Axi4SlaveBFM #(
        .DATA_BUS_WIDTH(32),
        .ADDRESS_WIDTH(32),
        .ID_WIDTH(4)
    ) slave_core (
        .ACLK(clk), .ARESETn(rst_n),
        .AWID(master_if.AWID), .AWADDR(master_if.AWADDR),
        .AWLEN(master_if.AWLEN), .AWSIZE(master_if.AWSIZE),
        .AWBURST(master_if.AWBURST), .AWLOCK(master_if.AWLOCK),
        .AWCACHE(master_if.AWCACHE), .AWPROT(master_if.AWPROT),
        .AWVALID(master_if.AWVALID), .AWREADY(master_if.AWREADY),
        .WDATA(master_if.WDATA), .WSTRB(master_if.WSTRB),
        .WLAST(master_if.WLAST), .WVALID(master_if.WVALID),
        .WREADY(master_if.WREADY), .BID(master_if.BID),
        .BRESP(master_if.BRESP), .BVALID(master_if.BVALID),
        .BREADY(master_if.BREADY), .ARID(master_if.ARID),
        .ARADDR(master_if.ARADDR), .ARLEN(master_if.ARLEN),
        .ARSIZE(master_if.ARSIZE), .ARBURST(master_if.ARBURST),
        .ARLOCK(master_if.ARLOCK), .ARCACHE(master_if.ARCACHE),
        .ARPROT(master_if.ARPROT), .ARVALID(master_if.ARVALID),
        .ARREADY(master_if.ARREADY), .RID(master_if.RID),
        .RDATA(master_if.RDATA), .RRESP(master_if.RRESP),
        .RLAST(master_if.RLAST), .RVALID(master_if.RVALID),
        .RREADY(master_if.RREADY),
        .AWREGION(), .AWQOS(), .AWUSER(), .ARREGION(), .ARQOS(),
        .ARUSER(), .RUSER(), .WUSER(), .BUSER()
    );

    // 6. Reset generation and simulation start
    initial begin
        clk = 0; rst_n = 0;
        #100 rst_n = 1;
        $display("[%0t] TB_TOP: Reset released. System ready.", $time);
    end

    // 7. SLAVE HANDLER - WRITE with memory storage
    initial begin
        axi_transaction #(32, 32, 4) s_wr_trans;
        s_wr_trans = new();
        wait(rst_n == 1);
        forever begin
            slave_core.get_write_addr_phase(s_wr_trans);
            slave_core.get_write_data_burst(s_wr_trans);
            // Store data in mem array: Address -> Data[0]
            mem[s_wr_trans.transaction_struct.address] = s_wr_trans.transaction_struct.wdata[0];
            void'(s_wr_trans.set_write_resp(2'b00)); // OKAY
            slave_core.execute_write_response_phase(s_wr_trans);
        end
    end

    // 8. SLAVE HANDLER - READ with memory retrieval
    initial begin
        axi_transaction #(32, 32, 4) s_rd_trans;
        s_rd_trans = new();
        wait(rst_n == 1);
        forever begin
            slave_core.get_read_addr_phase(s_rd_trans);
            // Check if address exists in memory, else return 32'hBAADCAFE
            if (mem.exists(s_rd_trans.transaction_struct.address)) begin
                void'(s_rd_trans.set_data_words(mem[s_rd_trans.transaction_struct.address], 0));
            end else begin
                void'(s_rd_trans.set_data_words(32'hBAADCAFE, 0));
            end
            void'(s_rd_trans.set_read_resp(2'b00)); // OKAY
            s_rd_trans.copy_wdata_to_rdata();
            slave_core.execute_read_data_burst(s_rd_trans);
        end
    end

    // 9. Command Interpreter Instance
    axi_interpreter interpreter_i (.clk(clk), .rst_n(rst_n));

endmodule