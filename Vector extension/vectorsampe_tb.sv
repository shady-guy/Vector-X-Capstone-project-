`timescale 1ns/1ps

module tb_vector_vadd;

  localparam LANES  = 4;
  localparam SEW    = 32;
  localparam MAX_VL = 64;

  logic clk, rst;
  logic start;
  logic [$clog2(MAX_VL)-1:0] vl;
  logic done;

  logic [SEW-1:0] vs1 [MAX_VL];
  logic [SEW-1:0] vs2 [MAX_VL];
  logic [SEW-1:0] vd  [MAX_VL];

  // DUT
  vector_vadd_execute #(
    .LANES(LANES),
    .SEW(SEW),
    .MAX_VL(MAX_VL)
  ) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .vl(vl),
    .done(done),
    .vs1(vs1),
    .vs2(vs2),
    .vd(vd)
  );

  // Clock: 10ns period
  always #5 clk = ~clk;

  integer cycle_count;

  initial begin
    clk = 0;
    rst = 1;
    start = 0;
    vl = 0;
    cycle_count = 0;

    // Initialize vectors
    for (int i = 0; i < MAX_VL; i++) begin
      vs1[i] = i;
      vs2[i] = i * 10;
      vd[i]  = 0;
    end

    #20 rst = 0;

    // Issue vector instruction
    vl = 10;
    start = 1;
    #10 start = 0;

    // Count cycles until done
    while (!done) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("Vector instruction completed in %0d cycles", cycle_count);

    // Check results
    for (int i = 0; i < vl; i++) begin
      $display("vd[%0d] = %0d", i, vd[i]);
    end

    $finish;
  end

endmodule
