module tb_riscv_sc;
//cpu testbench

reg clk;
reg start;

FullyPipelinedCore riscv_DUT(clk, start);

initial clk = 0;  // separate, guaranteed first

initial
    forever #5 clk = ~clk;

initial begin
    start = 0;
    #10 start = 1;
    #3000 $finish;

end

endmodule
