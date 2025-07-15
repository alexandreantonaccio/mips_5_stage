`timescale 1ns/1ps

module tb_mips_branch();

    // Sinais para conectar ao DUT
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    // Parâmetro para controlar a duração da simulação
    parameter MAX_CYCLES = 20;

    // Instancia o processador pipelined
    // IMPORTANTE: Altere o módulo 'imem' no seu processador para carregar "branch.txt"
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

        // Cabeçalho para monitorar sinais relevantes, incluindo controle de desvio (se disponível)
        // Se seu design tiver um sinal para flush ou seleção de PC, adicione-o aqui.
        $display("Ciclo | PC_IF      | Instr_ID   | ALUOut_MEM | Result_WB");
        $display("------------------------------------------------------------------");

        repeat (MAX_CYCLES) begin
            @(posedge clk);
            // O display monitora os estágios chave para observar o fluxo do programa
            $display("%5d | %h | %h | %h   | %h",
                $time/10,              // Ciclo atual
                dut.pc_f,              // PC no estágio IF (para ver os saltos)
                dut.instr_d,           // Instrução no estágio ID (para ver instruções descartadas)
                dut.aluout_m,          // Saída da ALU no final do estágio MEM
                dut.result_w           // Resultado sendo escrito no WB
            );
        end

        // --- VERIFICAÇÃO FINAL ---
        // Seção para verificar se os valores finais dos registradores correspondem ao esperado
        // após a execução dos desvios.
        $display("\n=======================================================");
        $display("--- Simulação finalizada ---");
        $display("Valores finais esperados para o teste de desvio:");
        $display("$t0=1, $t1=1, $s2=2, $s0=0 (desvio pulou), $s1=5 (alvo do desvio)");
        $display("-------------------------------------------------------");
        $display("Valores finais medidos nos registradores:");
        
        // Acessa o banco de registradores (rf) do DUT para verificação
        $display("Valor final em $t0 (R8) : %d", dut.rf.rf[8]);
        $display("Valor final em $t1 (R9) : %d", dut.rf.rf[9]);
        $display("Valor final em $s0 (R16): %d", dut.rf.rf[16]);
        $display("Valor final em $s1 (R17): %d", dut.rf.rf[17]);
        $display("Valor final em $s2 (R18): %d", dut.rf.rf[18]);

        $finish;
    end

endmodule