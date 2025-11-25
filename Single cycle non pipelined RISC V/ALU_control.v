`timescale 1ns/1ps
module ALU_control ( 
    input [1:0]aluop,
    input [3:0]funct,
    output reg [3:0] ALU_control
);

always @(*) begin
    ALU_control <=4'b0;
    case (aluop)
    2'b00 : ALU_control <= 4'b0011; //lw or sw -> need to add
    2'b01 : ALU_control <= 4'b0100; //branch (beq) -> need to subtract
    2'b10 : ALU_control <= funct;
    default : ALU-control <= 4'b1111;
    endcase
end
endmodule 


    //example
    //ld x2, [x8], #04 -> value stored at address value x8 +4 is stored in x2
    //ld x3, [x9],
    //add x1,x2,x3
    //x3 =4 (say)
    //beq x2, x3, #4 (target=32) -> pc moves to 32 since x3==4 (checked by x3-4 ==0)
    
