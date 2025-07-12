`timescale 1ns/1ps

module tb_mips_jal();

    // Sinais para conectar ao DUT (Device Under Test)
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    // Parâmetro para controlar a duração da simulação
    // O programa é curto, 30 ciclos são suficientes para ver todo o fluxo.
    parameter MAX_CYCLES = 30;

    // Instancia o processador pipelined
    // IMPORTANTE: Certifique-se que o módulo 'imem' dentro do seu processador
    // está carregando "teste_jal.txt" em vez de "sort.txt".
    mips_5_stage dut (
        .clk(clk),
        .reset(reset),
        .writedata_out(writedata),
        .dataadr_out(dataadr),
        .memwrite_out(memwrite)
    );

    // Geração de clock: período de 10ns
    always #5 clk = ~clk;

    // Bloco principal da simulação
    initial begin
        // --- SETUP ---
        clk = 0;
        reset = 1;
        #15; // Mantém o reset ativo por alguns ciclos
        reset = 0;
        #1;

        // --- EXECUÇÃO POR NÚMERO FIXO DE CICLOS ---
        $display("\n=======================================================");
        $display("--- Iniciando a execução do teste de JAL/JR por %d ciclos ---", MAX_CYCLES);
        $display("=======================================================\n");
        repeat (MAX_CYCLES) @(posedge clk);

        // --- VERIFICAÇÃO FINAL ---
        $display("\n=======================================================");
        $display("--- Simulação finalizada após %d ciclos ---", MAX_CYCLES);
        $display("Valor final em $t0 (reg 8): %d", dut.rf.rf[8]);
        $display("Valor final em $t1 (reg 9): %d", dut.rf.rf[9]);
        $display("Valor final em $ra (reg 31): 0x%h", dut.rf.rf[31]);

        // Verifica se os valores finais estão corretos
        if (dut.rf.rf[8] == 15 && dut.rf.rf[9] == 100) begin
            $display("\n>>> SUCESSO: Os valores nos registradores $t0 e $t1 estão corretos!");
        end else begin
            $display("\n>>> FALHA: Os valores nos registradores estão incorretos!");
        end
        $display("=======================================================\n");

        $finish;
    end

    // Bloco de monitoramento de registradores
    // Exibe o estado dos registradores relevantes para o teste a cada ciclo
    always @(negedge clk) begin
        if (!reset) begin
            // Monitora o PC e os registradores $t0, $t1, e $ra
            $display("PC_F=%h | $t0=%d, $t1=%d, $ra=0x%h | Instr_D=%h, ALU_M=%h",
                dut.pc_f,
                dut.rf.rf[8],  // $t0
                dut.rf.rf[9],  // $t1
                dut.rf.rf[31], // $ra
                dut.instr_d,   // Instrução no estágio de Decode
                dut.aluout_m   // Saída da ALU no estágio Memory
            );
        end
    end

endmodule
