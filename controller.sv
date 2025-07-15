module controller(input  logic [5:0] op, funct, input  logic zeroNzero, output logic memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, jr, jal, output logic [2:0] alucontrol);
  logic [1:0] aluop;
  maindec md(op, funct, memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, jr, jal, aluop);
  aludec  ad(funct, aluop, alucontrol);
endmodule