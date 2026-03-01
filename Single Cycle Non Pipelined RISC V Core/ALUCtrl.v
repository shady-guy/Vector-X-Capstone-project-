module ALUCtrl (
    input [1:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,
    output reg [3:0] ALUCtl
);

   
   always@(*) begin
       case(ALUOp)
           2'b00: ALUCtl = 4'b0000; // for LW and SW, Operation is addition
           2'b01: ALUCtl = funct3[2] ? 4'b0010 : 4'b1000; // SLT for blt and bge, subtraction for beq, bne
           2'b10: begin
                  ALUCtl = {1'b0, funct3};  // for R-type instruction, it depends on funct3 and funct7
                  if((funct3==0 | funct3==5) & (funct7[5])) ALUCtl = ALUCtl + 4'b1000; // handles add / sub and srl / sra
           end
           2'b11: begin // for I-type instructions, it depends on funct3
                  ALUCtl = {1'b0, funct3};  // for R-type instruction, it depends on funct3 and funct7
                  if(funct3==5 & funct7[5]) ALUCtl = ALUCtl + 4'b1000; // handles srli / srai
           end
           default: ALUCtl = 4'b1111;
       endcase
   end

endmodule

