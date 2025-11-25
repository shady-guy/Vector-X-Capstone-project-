`timescale 1ns/1ps
//clock not required. pc's auto-incrementing behaves like a clk
module instruction_mem (
    input reset,
    input [31:0] pc, 
    output reg [31:0] instruction
);

reg [31:0] memory[0:31]; //32 entries of 32 bits each

initial begin
    memory[0]=32'h0;
    memory[1]=32'h000000000011_00000_010_00001_0010011;
    memory[2]=32'h000000000101_00000_010_00010_0010011;
end

for(integer i=0; i<32; i=i+1) begin
    memory[i]=32'h0000000_0001_00010_010_00010_0110011;
end

always@(*) begin
    if (reset) begin
        instruction <=0;
    end
    else begin
        instruction <= memory[pc>>2 & 5'b11111];
    end
end

endmodule

