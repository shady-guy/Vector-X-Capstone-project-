`timescale 1ns/1ps

module pc (
    input clk,
    input reset,
    output reg [31:0] pc,
    input [31:0] next
);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        pc <=0;
        end
    else begin
        pc <= next; // next value of program counter may be some value (not always pc +4)
    end
end
endmodule 


