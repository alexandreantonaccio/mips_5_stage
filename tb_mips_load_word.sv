`timescale 1ns/1ps

module tb_mips_load_word(); 
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;
    parameter MAX_CYCLES = 15;
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
        $display("\n=======================================================");
        $display("--- Simulação finalizada ---");
        $display("Valores finais esperados:");
        $display("$s0 = 1, $s1 = 1, $s2 = 3, $t0 = 2, $t1 = 4, $t2 = 4, mem[4] = 1");
        $display("-------------------------------------------------------");
        $display("Valores finais nos registradores e memória:");
        $display("Valor final em $s0 (R16): %d", dut.rf.rf[16]);
        $display("Valor final em $s1 (R17): %d", dut.rf.rf[17]);
        $display("Valor final em $s2 (R18): %d", dut.rf.rf[18]);
        $display("Valor final em $t0 (R8) : %d", dut.rf.rf[8]);
        $display("Valor final em $t1 (R9) : %d", dut.rf.rf[9]);
        $display("Valor final em $t2 (R10): %d", dut.rf.rf[10]);
        $display("Valor final em mem[4]   : %d", dut.dmem.RAM[1]); 

        $finish;
    end

endmodule