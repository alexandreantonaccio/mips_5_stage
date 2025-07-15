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