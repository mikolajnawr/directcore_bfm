`timescale 1ns/1ps
import Ax_AlteraBFMWrapperPkg::*; 

module axi_interpreter (
    input bit clk,
    input bit rst_n
);

    axi_transaction #(32, 32, 4) trans_obj;

    initial begin
        int file_h;
        int status;
        string cmd;
        logic [31:0] addr, data;

        $display("***************************************************");
        $display("[%0t] >>> INTERPRETER: MODULE STARTED <<<", $time);
        $display("***************************************************");
        
        trans_obj = new();
        
        wait(rst_n == 1);
        repeat(5) @(posedge clk);

        // Open script file
        file_h = $fopen("../scripts/test_v1.txt", "r");
        if (!file_h) begin
            $error("[%0t] ERROR: Could not open ../scripts/test_v1.txt!", $time);
            $finish;
        end else begin
            $display("[%0t] DEBUG: Script file opened successfully.", $time);
        end

        // Main Loop
        while (!$feof(file_h)) begin
            status = $fscanf(file_h, "%s", cmd);
            
            // Skip comments and empty lines
            if (status <= 0 || cmd.substr(0,0) == "#") begin
                string dummy; 
                void'($fgets(dummy, file_h)); 
                continue;
            end

            case (cmd)
                "WRITE": begin
                    status = $fscanf(file_h, "%h %h", addr, data);
                    $display("[%0t] SCRIPT EXEC: WRITE Addr: 0x%h Data: 0x%h", $time, addr, data);
                    
                    void'(trans_obj.set_address(addr));
                    void'(trans_obj.set_data_words(data, 0));
                    void'(trans_obj.set_write(1'b1));
                    void'(trans_obj.set_size(3'b010)); // 4 bytes
                    
                    $root.tb_top.master_core.execute_transaction(trans_obj);
                end
                
                "READ": begin
                    status = $fscanf(file_h, "%h", addr);
                    $display("[%0t] SCRIPT EXEC: READ Addr: 0x%h", $time, addr);
                    
                    void'(trans_obj.set_address(addr));
                    void'(trans_obj.set_write(1'b0)); 
                    
                    $root.tb_top.master_core.execute_transaction(trans_obj);
                    
                    data = trans_obj.get_data_words(0);
                    $display("[%0t] BFM READ RESULT: 0x%h", $time, data);
                end
                
                "WAIT": begin
                    status = $fscanf(file_h, "%d", data);
                    $display("[%0t] SCRIPT EXEC: WAIT %0d clock cycles", $time, data);
                    repeat(data) @(posedge clk);
                end
                
                default: begin
                    $display("[%0t] WARNING: Unknown command in script: %s", $time, cmd);
                end
            endcase
        end

        $display("[%0t] --- SCRIPT FINISHED SUCCESSFULLY ---", $time);
        repeat(50) @(posedge clk);
        $stop;
    end
endmodule