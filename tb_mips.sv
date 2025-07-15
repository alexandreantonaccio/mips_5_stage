`timescale 1ns/1ps

module tb_mips_beq();

    // Sinais para conectar ao DUT
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    // Parâmetro para controlar a duração da simulação
    parameter MAX_CYCLES = 20;

    // Instancia o processador pipelined
    // IMPORTANTE: Altere o módulo 'imem' no seu processador para carregar "fwd_test.txt"
    mips_5_stage dut (
        .clk(clk),
        .reset(reset),
        .writedata_out(writedata),
        .dataadr_out(dataadr),
        .memwrite_out(memwrite)
    );

    // Geração de clock
    always #5 clk = ~clk;

    // Bloco principal da simulação
    initial begin
        // --- SETUP ---
        clk = 0;
        reset = 1;
        #15;
        reset = 0;
        #1;

        // CORREÇÃO: Cabeçalho atualizado para refletir os sinais que existem no DUT
        $display("Ciclo | PC_IF      | Instr_ID   | FwdA | FwdB | ALU_SrcA_EX| ALU_SrcB_EX| ALUOut_MEM | Result_WB");
        $display("----------------------------------------------------------------------------------------------------");

        repeat (MAX_CYCLES) begin
            @(posedge clk);
            // CORREÇÃO: O display agora usa apenas sinais válidos do seu módulo 'mips_pipelined'
            $display("%5d | %h | %h |  %b  |  %b  | %h | %h | %h   | %h",
                $time/10,              // Ciclo atual
                dut.pc_f,              // PC no estágio IF
                dut.instr_d,           // Instrução no estágio ID
                dut.forward_a_e,       // Sinal de Forward para operando A
                dut.forward_b_e,       // Sinal de Forward para operando B
                dut.srca_forwarded_e,  // Operando A real entrando na ALU (Estágio EX)
                dut.srcb_alu_e,        // Operando B real entrando na ALU (Estágio EX)
                dut.aluout_m,          // Saída da ALU no final do estágio MEM
                dut.result_w           // Resultado sendo escrito no WB
            );
        end

        // --- VERIFICAÇÃO FINAL ---
        $display("\n=======================================================");
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
