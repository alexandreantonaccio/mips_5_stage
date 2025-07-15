`timescale 1ns/1ps

module tb_mips_load_word(); // Nome do módulo alterado para refletir o teste

    // Sinais para conectar ao DUT
    logic clk, reset;
    logic [31:0] writedata, dataadr;
    logic memwrite;

    // Parâmetro para controlar a duração da simulação
    // Aumentado para garantir a execução de todas as instruções
    parameter MAX_CYCLES = 15;

    // Instancia o processador pipelined
    // IMPORTANTE: Certifique-se que o módulo 'imem' no seu processador carregue "load_word.txt"
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

        // Cabeçalho para monitoramento dos sinais durante a execução
        $display("Ciclo | PC_IF      | Instr_ID   | FwdA | FwdB | ALU_SrcA_EX| ALU_SrcB_EX| ALUOut_MEM | Result_WB");
        $display("----------------------------------------------------------------------------------------------------");

        repeat (MAX_CYCLES) begin
            @(posedge clk);
            // Display dos sinais internos do pipeline a cada ciclo de clock
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
        // Seção alterada para monitorar os registradores e memória relevantes para load_word.txt
        $display("\n=======================================================");
        $display("--- Simulação finalizada ---");
        $display("Valores finais esperados:");
        $display("$s0 = 1, $s1 = 1, $s2 = 3, $t0 = 2, $t1 = 4, $t2 = 4, mem[4] = 1");
        $display("-------------------------------------------------------");
        $display("Valores finais nos registradores e memória:");
        
        // Acessa o banco de registradores (rf) e a memória de dados (dmem) do DUT
        $display("Valor final em $s0 (R16): %d", dut.rf.rf[16]);
        $display("Valor final em $s1 (R17): %d", dut.rf.rf[17]);
        $display("Valor final em $s2 (R18): %d", dut.rf.rf[18]);
        $display("Valor final em $t0 (R8) : %d", dut.rf.rf[8]);
        $display("Valor final em $t1 (R9) : %d", dut.rf.rf[9]);
        $display("Valor final em $t2 (R10): %d", dut.rf.rf[10]);
        
        // O endereço de memória é 4, que corresponde ao índice 1 do array RAM (assumindo alinhamento de 4 bytes)
        $display("Valor final em mem[4]   : %d", dut.dmem.RAM[1]); 

        $finish;
    end

endmodule