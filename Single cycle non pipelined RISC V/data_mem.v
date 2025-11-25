`timescale 1ns/ 1ps

module data_mem (
    input clk, mem_write, mem_read,
    input [31:0] address, write_data, //address is used as is 
    output [31:0] read_data
);

reg [31:0]mem[0:31];
integer i;
initial begin 
    for (i =0; i<32 ; i=i+1) begin
        mem[i]= {32(1'b0)};
    end
end

always @(posedge clk) begin
    if(mem_write) begin
        mem[address] <= write_data;
    end
end

assign read_data (mem_read)? mem[address] : 32'b0;

endmodule 