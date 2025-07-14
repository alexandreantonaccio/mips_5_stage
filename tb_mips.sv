`timescale 1ns/1ps

module tb_mips_forwarding();

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

        // Pré-carrega valores nos registradores para um resultado previsível
        // Este acesso direto só funciona em simulação
        dut.rf.rf[17] = 10; // $s1 = 10
        dut.rf.rf[18] = 20; // $s2 = 20
        $display("Valores Iniciais: $s1=10, $s2=20");


        // --- EXECUÇÃO ---
        $display("\n====================================================================================================");
        $display("--- Iniciando teste de Forwarding por %d ciclos ---", MAX_CYCLES);
        $display("====================================================================================================");
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
        $display("Valor final em $s0 (reg 16): %d", dut.rf.rf[16]); // Esperado: 1
        $display("Valor final em $s1 (reg 17): %d", dut.rf.rf[17]); // Esperado: 12
        $display("Valor final em $s2 (reg 18): %d", dut.rf.rf[18]); // Esperado: 20 (inalterado)
        $display("Valor final em $s3 (reg 19): %d", dut.rf.rf[19]); // Esperado: 32

        if (dut.rf.rf[16] == 1 && dut.rf.rf[17] == 12 && dut.rf.rf[19] == 32) begin
            $display("\n>>> SUCESSO: O Forwarding funcionou e os valores nos registradores estão corretos!");
        end else begin
            $display("\n>>> FALHA: Valores incorretos nos registradores!");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
