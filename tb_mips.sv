`timescale 1ns/1ps
module tb_mips_beq();
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;
    parameter MAX_CYCLES = 20;
    mips_5_stage dut (
        .clk(clk),
        .reset(reset),
        .writedata_out(writedata),
        .dataadr_out(dataadr),
        .memwrite_out(memwrite)
    ); 
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        #15;
        reset = 0;
        #1;
        $display("Ciclo | PC_IF      | Instr_ID   | FwdA | FwdB | ALU_SrcA_EX| ALU_SrcB_EX| ALUOut_MEM | Result_WB");
        $display("----------------------------------------------------------------------------------------------------");
        repeat (MAX_CYCLES) begin
            @(posedge clk);
            $display("%5d | %h | %h |  %b  |  %b  | %h | %h | %h   | %h",
                $time/10,              
                dut.pc_f,              
                dut.instr_d,           
                dut.forward_a_e,       
                dut.forward_b_e,       
                dut.srca_forwarded_e,  
                dut.srcb_alu_e,        
                dut.aluout_m,          
                dut.result_w           
            );
        end
        $display("--- Simulação finalizada ---");
        $display("Valor final em $t0 : %d", dut.rf.rf[8]);
        $display("Valor final em $t1 : %d", dut.rf.rf[9]);
        $display("Valor final em $t2 : %d", dut.rf.rf[10]);
        $display("Valor final em $t3 : %d", dut.rf.rf[11]); 
		  $display("Valor final em $t4 : %d", dut.rf.rf[12]); 
		  $display("Valor final em $t5 : %d", dut.rf.rf[13]); 
		  $display("Valor final em $t6 : %d", dut.rf.rf[14]); 
		  $display("Valor final em $t7 : %d", dut.rf.rf[15]); 
		  $display("Valor final em mem : %d", dut.dmem.RAM[9]);
        $finish;
    end
endmodule
