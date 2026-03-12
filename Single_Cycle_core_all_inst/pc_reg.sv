module pc_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] PC_next,
    output logic [31:0] PC
);
    always_ff @(posedge clk) begin
        if(rst) PC <= 32'b0;
        else    PC <= PC_next;
    end
endmodule
