module hazardunit(
    input  logic [4:0] rs_d, rt_d, rs_e, rt_e, writereg_m, writereg_w,
    input  logic       regwrite_m, regwrite_w, memtoreg_e,
    input  logic       pcsrc_e,
    output logic [1:0] forward_a_e, forward_b_e,
    output logic       stall_f, stall_d, flush_d, flush_e
);
    logic lw_stall;
    always_comb begin // Fowarding em EX e MEM para palavra A
        if (rs_e != 0 && rs_e == writereg_m && regwrite_m)
            forward_a_e = 2'b10;
        else if (rs_e != 0 && rs_e == writereg_w && regwrite_w)
            forward_a_e = 2'b01;
        else
            forward_a_e = 2'b00;
    end

    always_comb begin // Fowarding em EX e MEM para palavra A
        if (rt_e != 0 && rt_e == writereg_m && regwrite_m)
            forward_b_e = 2'b10;
        else if (rt_e != 0 && rt_e == writereg_w && regwrite_w)
            forward_b_e = 2'b01;
        else
            forward_b_e = 2'b00;
    end

    // Logica de Stall para Load-Use Hazard
    assign lw_stall = memtoreg_e && (rt_e == rs_d || rt_e == rt_d);
    assign stall_f = lw_stall;
    assign stall_d = lw_stall;

    // Logica de Flush robusta
    assign flush_e = lw_stall || pcsrc_e;
    assign flush_d = pcsrc_e;

endmodule
