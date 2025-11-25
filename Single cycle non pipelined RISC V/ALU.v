`timescale 1ns/1ps

module ALU (
    input [3:0] ALU_control,
    input [31:0] I1, I2,
    output reg [31:0] alu_out,
    output reg N,Z,C,V
);

always@(*) begin
    case (ALU_ontrol) 
    4'b0000 : alu_out = I1 & I2; //AND
    4'b0001 : alu_out = I1 | I2; //OR
    4'b0010 : alu_out = I1 ^ I2; //XOR
    4'b0011 : {C,alu_out} = I1 + I2; //ADD
    4'b0100 : {C,alu_out} = I1 - I2; //SUB
    4'b0101 : alu_out = I1 >> I2; //RIGHT SHIFT
    4'b0110 : alu_out = I1 << I2; //LEFT SHIFT
    4'b0111 : alu_out = ~(I1 & I2); //NAND
    4'b1000 : alu_out = ~(I1 | I2); //NOR
    4'b1001 : alu_out = ~(I1 ^ I2); //XNOR
    4'b1010 : alu_out = (I1 < I2)? 1:0; //LT
    4'b1011 : alu_out = (I1 == I2)? 1:0; //EQ
    default : alu_out =0;
    endcase

    N = alu_out[31]; //negative flag
    Z = (alu_out==0) ? 1:0; //zero flag
    V = (I1[31]==I2[31] ? I[31]:0) ^ alu_out[31]; //overflow flag

    end
endmodule
