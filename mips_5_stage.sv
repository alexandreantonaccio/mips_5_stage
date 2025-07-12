`timescale 1ns/1ps

//================================================================
// Modulo Principal do Processador Pipelined
//================================================================
module mips_5_stage(
    input  logic        clk, reset,
    output logic [31:0] writedata_out, dataadr_out,
    output logic        memwrite_out
);

    // Sinais e Fios Internos
    // --- Estágio IF ---
    logic [31:0] pc_f;
    logic [31:0] instr_f;
    logic        stall_f;

    // --- Registrador IF/ID ---
    logic [31:0] pcplus4_d, instr_d;

    // --- Estágio ID ---
    logic [31:0] srca_d, srcb_d, signimm_d;
    logic        stall_d, flush_d, flush_e;
    logic        memtoreg_d, memwrite_d, alusrc_d, regdst_d, regwrite_d, jump_d, jr_d, jal_d, branch_d;
    logic [2:0]  alucontrol_d;

    // --- Registrador ID/EX ---
    logic [31:0] pcplus4_e, srca_e, srcb_e, signimm_e;
    logic        memtoreg_e, memwrite_e, alusrc_e, regdst_e, regwrite_e, jal_e, branch_e; // CORREÇÃO: Removido jump_e, jr_e (não utilizados)
    logic [2:0]  alucontrol_e;
    logic [4:0]  rs_e, rt_e, rd_e, shamt_e;

    // --- Estágio EX ---
    logic [1:0]  forward_a_e, forward_b_e;
    logic [31:0] srca_forwarded_e, srcb_forwarded_e, srcb_alu_e;
    logic [31:0] aluout_e;
    logic [4:0]  writereg_e, writereg_e_temp;
    logic        zero_e;

    // --- Registrador EX/MEM ---
    logic [31:0] aluout_m, srcb_m, pcplus4_m;
    logic        memtoreg_m, memwrite_m, regwrite_m, branch_m, zero_m, jal_m;
    logic [4:0]  writereg_m;
    logic [31:0] pcbranch_m;

    // --- Estágio MEM ---
    logic [31:0] readdata_m;
    logic        pcsrc_m;

    // --- Registrador MEM/WB ---
    logic [31:0] aluout_w, readdata_w, pcplus4_w;
    logic        memtoreg_w, regwrite_w, jal_w;
    logic [4:0]  writereg_w;

    // --- Estágio WB ---
    logic [31:0] result_w, result_w_temp;

    //================================================================
    // Estágio IF (Instruction Fetch)
    //================================================================
    // CORREÇÃO: O pcreg agora usa o flopr síncrono corrigido
    flopr #(32) pcreg(clk, reset, (stall_f | stall_d), pcsrc_m ? pcbranch_m : (jump_d | jr_d | jal_d) ? (jr_d ? srca_d : {pcplus4_d[31:28], instr_d[25:0], 2'b00}) : pc_f + 4, pc_f);

    imem imem(pc_f[7:2], instr_f);

    //================================================================
    // Registrador de Pipeline IF/ID
    //================================================================
    // CORREÇÃO: Lógica síncrona padrão para evitar latches e erros de elaboração
    always_ff @(posedge clk) begin
        if (reset) begin
            instr_d <= 32'b0;
            pcplus4_d <= 32'b0;
        end else if (flush_d) begin
            instr_d <= 32'b0; // Insere NOP
            pcplus4_d <= 32'b0;
        end else if (~(stall_f | stall_d)) begin
            instr_d <= instr_f;
            pcplus4_d <= pc_f + 4;
        end
        // Se estiver em stall, mantém o valor anterior (comportamento de flip-flop com enable)
    end

    //================================================================
    // Estágio ID (Instruction Decode & Register Fetch)
    //================================================================
    controller c(
        .op(instr_d[31:26]),
        .funct(instr_d[5:0]),
        .zeroNzero(zero_m),
        .memtoreg(memtoreg_d),
        .memwrite(memwrite_d),
        .branch(branch_d),
        .alusrc(alusrc_d),
        .regdst(regdst_d),
        .regwrite(regwrite_d),
        .jump(jump_d),
        .jr(jr_d),
        .jal(jal_d),
        .alucontrol(alucontrol_d)
    );

    regfile rf(
        .clk(clk),
        .we3(regwrite_w),
        .ra1(instr_d[25:21]),
        .ra2(instr_d[20:16]),
        .wa3(writereg_w),
        .wd3(result_w),
        .rd1(srca_d),
        .rd2(srcb_d)
    );

    assign signimm_d = {{16{instr_d[15]}}, instr_d[15:0]};

    //================================================================
    // Registrador de Pipeline ID/EX
    //================================================================
    // CORREÇÃO: Lógica síncrona padrão
    always_ff @(posedge clk) begin
        if (reset || flush_e) begin // Limpa o registrador em reset ou flush de branch
            // Sinais de controle (insere NOP)
            {regwrite_e, regdst_e, alusrc_e, branch_e, memwrite_e, memtoreg_e, jal_e} <= 0;
            alucontrol_e <= 0;
            // Dados
            pcplus4_e <= 0;
            srca_e <= 0;
            srcb_e <= 0;
            signimm_e <= 0;
            rs_e <= 0;
            rt_e <= 0;
            rd_e <= 0;
            shamt_e <= 0;
        end else begin
            // Sinais de controle
            {regwrite_e, regdst_e, alusrc_e, branch_e, memwrite_e, memtoreg_e, jal_e} <= {regwrite_d, regdst_d, alusrc_d, branch_d, memwrite_d, memtoreg_d, jal_d};
            alucontrol_e <= alucontrol_d;
            // Dados
            pcplus4_e <= pcplus4_d;
            srca_e <= srca_d;
            srcb_e <= srcb_d;
            signimm_e <= signimm_d;
            rs_e <= instr_d[25:21];
            rt_e <= instr_d[20:16];
            rd_e <= instr_d[15:11];
            shamt_e <= instr_d[10:6];
        end
    end

    //================================================================
    // Estágio EX (Execute)
    //================================================================
    mux3 #(32) forward_a_mux(srca_e, result_w, aluout_m, forward_a_e, srca_forwarded_e);
    mux3 #(32) forward_b_mux(srcb_e, result_w, aluout_m, forward_b_e, srcb_forwarded_e);

    mux2 #(32) srcb_mux(srcb_forwarded_e, signimm_e, alusrc_e, srcb_alu_e);

    alu alu(
        .a(srca_forwarded_e),
        .b(srcb_alu_e),
        .shamt(shamt_e),
        .alucontrol(alucontrol_e),
        .result(aluout_e),
        .zero(zero_e),
        .notzero()
    );

    mux2 #(5) writereg_mux(rt_e, rd_e, regdst_e, writereg_e_temp);
    mux2 #(5) jal_writereg_mux(writereg_e_temp, 5'b11111, jal_e, writereg_e);

    assign pcbranch_m = pcplus4_e + (signimm_e << 2);

    //================================================================
    // Registrador de Pipeline EX/MEM
    //================================================================
    // CORREÇÃO: Lógica síncrona padrão
    always_ff @(posedge clk) begin
        if (reset) begin
            {regwrite_m, branch_m, memwrite_m, memtoreg_m, zero_m, jal_m} <= 0;
            aluout_m <= 0;
            srcb_m <= 0;
            writereg_m <= 0;
            pcplus4_m <= 0;
        end else begin
            {regwrite_m, branch_m, memwrite_m, memtoreg_m, zero_m, jal_m} <= {regwrite_e, branch_e, memwrite_e, memtoreg_e, zero_e, jal_e};
            aluout_m <= aluout_e;
            srcb_m <= srcb_forwarded_e;
            writereg_m <= writereg_e;
            pcplus4_m <= pcplus4_e;
        end
    end

    //================================================================
    // Estágio MEM (Memory Access)
    //================================================================
    dmem dmem(
        .clk(clk),
        .we(memwrite_m),
        .a(aluout_m),
        .wd(srcb_m),
        .rd(readdata_m)
    );

    assign pcsrc_m = branch_m & zero_m;

    assign writedata_out = srcb_m;
    assign dataadr_out = aluout_m;
    assign memwrite_out = memwrite_m;

    //================================================================
    // Registrador de Pipeline MEM/WB
    //================================================================
    // CORREÇÃO: Lógica síncrona padrão
    always_ff @(posedge clk) begin
        if (reset) begin
            {regwrite_w, memtoreg_w, jal_w} <= 0;
            aluout_w <= 0;
            readdata_w <= 0;
            writereg_w <= 0;
            pcplus4_w <= 0;
        end else begin
            {regwrite_w, memtoreg_w, jal_w} <= {regwrite_m, memtoreg_m, jal_m};
            aluout_w <= aluout_m;
            readdata_w <= readdata_m;
            writereg_w <= writereg_m;
            pcplus4_w <= pcplus4_m;
        end
    end

    //================================================================
    // Estágio WB (Write Back)
    //================================================================
    mux2 #(32) result_mux(aluout_w, readdata_w, memtoreg_w, result_w_temp);
    mux2 #(32) jal_result_mux(result_w_temp, pcplus4_w, jal_w, result_w);

    //================================================================
    // Unidade de Hazard
    //================================================================
    hazardunit hu(
        .rs_d(instr_d[25:21]),
        .rt_d(instr_d[20:16]),
        .rs_e(rs_e),
        .rt_e(rt_e),
        .writereg_m(writereg_m),
        .writereg_w(writereg_w),
        .regwrite_m(regwrite_m),
        .regwrite_w(regwrite_w),
        .memtoreg_e(memtoreg_e),
        .pcsrc_m(pcsrc_m),
        .forward_a_e(forward_a_e),
        .forward_b_e(forward_b_e),
        .stall_f(stall_f),
        .stall_d(stall_d),
        .flush_d(flush_d),
        .flush_e(flush_e)
    );

endmodule


//================================================================
// Unidade de Hazard
//================================================================
module hazardunit(
    input  logic [4:0] rs_d, rt_d, rs_e, rt_e, writereg_m, writereg_w,
    input  logic       regwrite_m, regwrite_w, memtoreg_e, pcsrc_m,
    output logic [1:0] forward_a_e, forward_b_e,
    output logic       stall_f, stall_d, flush_d, flush_e
);
    logic lw_stall;

    always_comb begin
        if (rs_e != 0 && rs_e == writereg_m && regwrite_m)
            forward_a_e = 2'b10;
        else if (rs_e != 0 && rs_e == writereg_w && regwrite_w)
            forward_a_e = 2'b01;
        else
            forward_a_e = 2'b00;
    end

    always_comb begin
        if (rt_e != 0 && rt_e == writereg_m && regwrite_m)
            forward_b_e = 2'b10;
        else if (rt_e != 0 && rt_e == writereg_w && regwrite_w)
            forward_b_e = 2'b01;
        else
            forward_b_e = 2'b00;
    end

    assign lw_stall = memtoreg_e && (rt_e == rs_d || rt_e == rt_d);
    assign flush_d = pcsrc_m;
    assign flush_e = pcsrc_m;
    assign stall_f = lw_stall;
    assign stall_d = lw_stall;

endmodule

//================================================================
// Módulos de Hardware (Controller, Memórias, ALU, etc.)
//================================================================
module controller(input  logic [5:0] op, funct, input  logic zeroNzero, output logic memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, jr, jal, output logic [2:0] alucontrol);
  logic [1:0] aluop;
  maindec md(op, funct, memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, jr, jal, aluop);
  aludec  ad(funct, aluop, alucontrol);
endmodule

module maindec(input  logic [5:0] op, funct, output logic memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, jr, jal, output logic [1:0] aluop);
  logic [10:0] controls;
  assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, jr, jal, aluop} = controls;
  always_comb
    case(op)
      6'b000000: if (funct == 6'b001000) controls <= 11'b00000001000; else controls <= 11'b11000000010;
      6'b100011: controls <= 11'b10100100000; // LW
      6'b101011: controls <= 11'b00101000000; // SW
      6'b000100: controls <= 11'b00010000001; // BEQ
      6'b000101: controls <= 11'b00010000001; // BNE
      6'b001010: controls <= 11'b10100000011; // SLTI
      6'b001000: controls <= 11'b10100000000; // ADDI
      6'b000010: controls <= 11'b00000010000; // J
      6'b000011: controls <= 11'b10000010100; // JAL
      default:   controls <= 11'bxxxxxxxxxxx;
    endcase
endmodule

module aludec(input  logic [5:0] funct, input  logic [1:0] aluop, output logic [2:0] alucontrol);
  always_comb
    case(aluop)
      2'b00: alucontrol <= 3'b010;
      2'b01: alucontrol <= 3'b110;
      2'b11: alucontrol <= 3'b111;
      default: case(funct)
          6'b000000: alucontrol <= 3'b011; // SLL
          6'b001000: alucontrol <= 3'bxxx; // JR
          6'b100000: alucontrol <= 3'b010; // add
          6'b100010: alucontrol <= 3'b110; // sub
          6'b100100: alucontrol <= 3'b000; // and
          6'b100101: alucontrol <= 3'b001; // or
          6'b101010: alucontrol <= 3'b111; // slt
          default:   alucontrol <= 3'bxxx;
        endcase
    endcase
endmodule

module regfile(input logic clk, we3, input logic [4:0] ra1, ra2, wa3, input logic [31:0] wd3, output logic [31:0] rd1, rd2);
  logic [31:0] rf[31:0];
  always_ff @(posedge clk) if (we3 && wa3 != 0) rf[wa3] <= wd3;
  assign rd1 = (ra1 != 0) ? ((we3 && ra1 == wa3) ? wd3 : rf[ra1]) : 0;
  assign rd2 = (ra2 != 0) ? ((we3 && ra2 == wa3) ? wd3 : rf[ra2]) : 0;
endmodule

module alu(input logic [31:0] a, b, input logic [4:0] shamt, input logic [2:0] alucontrol, output logic [31:0] result, output logic zero, notzero);
  always_comb
    case(alucontrol)
      3'b010: result = a + b;
      3'b110: result = a - b;
      3'b000: result = a & b;
      3'b001: result = a | b;
      3'b111: result = ($signed(a) < $signed(b)) ? 1 : 0;
      3'b011: result = b << shamt;
      default: result = 32'bx;
    endcase
  assign zero = (result == 32'b0);
  assign notzero = (result != 32'b0);
endmodule

module imem(input logic [5:0] a, output logic [31:0] rd);
  logic [31:0] RAM[63:0];
  initial $readmemh("teste_jal.txt", RAM);
  assign rd = RAM[a];
endmodule

module dmem(input logic clk, we, input logic [31:0] a, wd, output logic [31:0] rd);
  logic [31:0] RAM[63:0];
  initial $readmemh("data.txt", RAM);
  assign rd = RAM[a[31:2]];
  always_ff @(posedge clk) if (we) RAM[a[31:2]] <= wd;
endmodule


//================================================================
// Módulos Utilitários
//================================================================
// CORREÇÃO: flopr reescrito para ser puramente síncrono
module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset, stall,
               input  logic [WIDTH-1:0] d,
               output logic [WIDTH-1:0] q);
  always_ff @(posedge clk) begin
    if (reset) begin
        q <= 0;
    end else if (~stall) begin
        q <= d;
    end
  end
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, input  logic s, output logic [WIDTH-1:0] y);
  assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2, input  logic [1:0] s, output logic [WIDTH-1:0] y);
  always_comb
    case(s)
      2'b01: y = d1;
      2'b10: y = d2;
      default: y = d0;
    endcase
endmodule
