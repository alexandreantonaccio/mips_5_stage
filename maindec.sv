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