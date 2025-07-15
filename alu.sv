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