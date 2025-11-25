// instantiates all the modules with the required signals 
//iverilog -o mysim.vvp top.v top_tb.v
`timescale 1ns/1ps

module datapath(
    input clk, reset
)

registers reg1 (
    .clk(clk), //can be pc. check
    .reset(reset),
    .
)