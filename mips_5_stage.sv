`timescale 1ns/1ps

module mips_5_stage(
    input  logic       clk, reset,
    output logic [31:0] writedata_out, dataadr_out,
    output logic       memwrite_out
);

    // --- Estágio IF ---
    logic [31:0] pc_f, instr_f;
    logic        stall_f;

    // --- Registrador IF/ID ---
    logic [31:0] pcplus4_d, instr_d;

    // --- Estágio ID ---
    logic [31:0] srca_d, srcb_d, signimm_d;
    logic        stall_d, flush_d;
    logic        memtoreg_d, memwrite_d, alusrc_d, regdst_d, regwrite_d, jump_d, jr_d, jal_d, branch_d;
    logic [2:0]  alucontrol_d;

    // --- Registrador ID/EX ---
    logic [31:0] pcplus4_e, srca_e, srcb_e, signimm_e;
    logic        memtoreg_e, memwrite_e, alusrc_e, regdst_e, regwrite_e, jal_e, branch_e;
    logic [2:0]  alucontrol_e;
    logic [4:0]  rs_e, rt_e, rd_e, shamt_e;
    logic        flush_e; 

    // --- Estágio EX ---
    logic [1:0]  forward_a_e, forward_b_e;
    logic [31:0] srca_forwarded_e, srcb_forwarded_e, srcb_alu_e;
    logic [31:0] aluout_e;
    logic [4:0]  writereg_e;
    logic        zero_e;
    logic [31:0] pcbranch_e;
    logic        pcsrc_e;   

    // --- Registrador EX/MEM ---
    logic [31:0] aluout_m, srcb_m, pcplus4_m;
    logic        memtoreg_m, memwrite_m, regwrite_m, jal_m;
    logic [4:0]  writereg_m;

    // --- Estágio MEM ---
    logic [31:0] readdata_m;

    // --- Registrador MEM/WB ---
    logic [31:0] aluout_w, readdata_w, pcplus4_w;
    logic        memtoreg_w, regwrite_w, jal_w;
    logic [4:0]  writereg_w;

    // --- Estágio WB ---
    logic [31:0] result_w;


    // ESTÁGIO IF - Busca de Instrução
    logic [31:0] pcnext, pcjump;
    assign pcjump = jr_d ? srca_d : {pcplus4_d[31:28], instr_d[25:0], 2'b00};
    assign pcnext = pcsrc_e ? pcbranch_e : (jump_d | jr_d) ? pcjump : pc_f + 4;

    flopr #(32) pcreg(clk, reset, (stall_f | stall_d), pcnext, pc_f);
    imem imem(pc_f[7:2], instr_f);

    // REGISTRADOR IF/ID
    always_ff @(posedge clk) begin
        if (reset) begin
            instr_d <= 32'b0;
            pcplus4_d <= 32'b0;
        end else if (~(stall_f | stall_d)) begin
            instr_d <= instr_f;
            pcplus4_d <= pc_f + 4;
        end
    end

    // ESTÁGIO ID - Decodificação e Leitura de Registradores
    controller c(
        .op(instr_d[31:26]),
        .funct(instr_d[5:0]),
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

    // REGISTRADOR ID/EX
    always_ff @(posedge clk) begin
        if (reset || flush_e) begin
            {regwrite_e, regdst_e, alusrc_e, branch_e, memwrite_e, memtoreg_e, jal_e} <= 0;
            alucontrol_e <= 0;
            pcplus4_e <= 0;
            srca_e <= 0;
            srcb_e <= 0;
            signimm_e <= 0;
            rs_e <= 0;
            rt_e <= 0;
            rd_e <= 0;
            shamt_e <= 0;
        end else begin
            {regwrite_e, regdst_e, alusrc_e, branch_e, memwrite_e, memtoreg_e, jal_e} <= {regwrite_d, regdst_d, alusrc_d, branch_d, memwrite_d, memtoreg_d, jal_d};
            alucontrol_e <= alucontrol_d;
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

    // ESTÁGIO EX - Execução
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

    mux2 #(5) writereg_mux(rt_e, rd_e, regdst_e, writereg_e);
    assign pcbranch_e = pcplus4_e + (signimm_e << 2);
    assign pcsrc_e = branch_e & zero_e;

    // REGISTRADOR EX/MEM
    always_ff @(posedge clk) begin
        if (reset) begin
            {regwrite_m, memwrite_m, memtoreg_m, jal_m} <= 0;
            aluout_m <= 0;
            srcb_m <= 0;
            writereg_m <= 0;
            pcplus4_m <= 0;
        end else begin
            {regwrite_m, memwrite_m, memtoreg_m, jal_m} <= {regwrite_e, memwrite_e, memtoreg_e, jal_e};
            aluout_m <= aluout_e;
            srcb_m <= srcb_forwarded_e;
            writereg_m <= writereg_e;
            pcplus4_m <= pcplus4_e;
        end
    end

    // ESTÁGIO MEM - Acesso à Memória
    dmem dmem(
        .clk(clk),
        .we(memwrite_m),
        .a(aluout_m),
        .wd(srcb_m),
        .rd(readdata_m)
    );

    // Saídas para o testbench
    assign writedata_out = srcb_m;
    assign dataadr_out = aluout_m;
    assign memwrite_out = memwrite_m;

    // REGISTRADOR MEM/WB
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

    // ESTÁGIO WB - Escrita de Volta
    logic [31:0] result_w_temp;
    mux2 #(32) result_mux(aluout_w, readdata_w, memtoreg_w, result_w_temp);
    mux2 #(32) jal_result_mux(result_w_temp, pcplus4_w, jal_w, result_w);

    // Unidade de Detecção de Hazards
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
        .pcsrc_e(pcsrc_e),
        .forward_a_e(forward_a_e),
        .forward_b_e(forward_b_e),
        .stall_f(stall_f),
        .stall_d(stall_d),
        .flush_d(flush_d),
        .flush_e(flush_e)
    );
endmodule