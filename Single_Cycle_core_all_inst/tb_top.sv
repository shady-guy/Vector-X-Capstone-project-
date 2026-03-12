module tb_top;

    logic clk, rst;

    // instantiate top
    top #(
        .IMEM_WORDS (64),
        .DMEM_WORDS (64),
        .IMEM_INIT  ("imem.hex"),
        .DMEM_INIT  ("dmem.hex")
    ) dut (
        .clk (clk),
        .rst (rst)
    );

    // clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // reset then run
    initial begin
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;
        repeat(100) @(posedge clk);
        $finish;
    end

    // waveform dump
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

    // monitor key signals every cycle
    always @(posedge clk) begin
        if(!rst) begin
            $display("t=%0t | PC=%h | instr=%h | rd_addr=%0d | wb_data=%h | mem_write=%b | alu_rslt=%h",
                $time,
                dut.PC,
                dut.instr,
                dut.rd_addr,
                dut.wb_data,
                dut.mem_write,
                dut.alu_rslt
            );
        end
    end

    // misalignment warning
    always @(posedge clk) begin
        if(!rst && dut.misalign)
            $display("WARNING: misaligned memory access at PC=%h addr=%h", dut.PC, dut.alu_rslt);
    end

endmodule
