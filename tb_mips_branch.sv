`timescale 1ns/1ps

module tb_mips_branch();
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
        $display("Ciclo | PC_IF      | Instr_ID   | ALUOut_MEM | Result_WB");
        $display("------------------------------------------------------------------");

        repeat (MAX_CYCLES) begin
            @(posedge clk);
            $display("%5d | %h | %h | %h   | %h",
                $time/10,              
                dut.pc_f,              
                dut.instr_d,           
                dut.aluout_m,          
                dut.result_w           
            );
        end
        $display("\n=======================================================");
        $display("--- Simulação finalizada ---");
        $display("Valores finais esperados para o teste de desvio:");
        $display("$t0=1, $t1=1, $s2=2, $s0=0 (desvio pulou), $s1=5 (alvo do desvio)");
        $display("-------------------------------------------------------");
        $display("Valores finais medidos nos registradores:");
        $display("Valor final em $t0 (R8) : %d", dut.rf.rf[8]);
        $display("Valor final em $t1 (R9) : %d", dut.rf.rf[9]);
        $display("Valor final em $s0 (R16): %d", dut.rf.rf[16]);
        $display("Valor final em $s1 (R17): %d", dut.rf.rf[17]);
        $display("Valor final em $s2 (R18): %d", dut.rf.rf[18]);
        $finish;
    end

endmodule