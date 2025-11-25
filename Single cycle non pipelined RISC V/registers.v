`timescale 1ns/1ps

module registers (
    input clk, 
    input reset, 
    input reg_write,
    input [4:0] read_reg1, read_reg2, write_reg;
    input [31:0] write_data,
    output [31:0] read_data1, read_data2;
);

reg [31:0]regi[0:31];

assign read_data1 =regi[read_reg1];  //index of read_reg1
assign read_data2 =regi[read_reg2];  //index of read_reg2

integer i;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i=0; i<32, i=i+1) begin
            regi[i] <=0;
        end
        else if(reg_write) begin
            regi[write_reg] <= write_data; //when reg_write is high, value in write_data written at write_reg index
        end
    end
end

endmodule
