module if_id_reg(
    input rst,
    input clk,
    input [31:0] pc_i,
    input [31:0] inst_i,
    output reg [31:0] pc_o,
    output reg [31:0] inst_o,
    
    //from hazard unit
    input flush_if_id,
    input wr_if_id,
   
    input [31:0] pcplus4_i,
    output reg [31:0] pcplus4_o
);

always @(posedge clk) begin
    if (~rst) begin
        pc_o <= 32'b0;
        inst_o <= 32'b0;
        pcplus4_o <= 32'b0;
    end
    //flush case
    else if (flush_if_id) begin
        pc_o <= pc_i; //could be 32'b0 also
        inst_o <= 32'b0;
        pcplus4_o <= 32'b0;
    end
    //if not stalled
    else if (wr_if_id) begin
        pc_o <= pc_i; 
        inst_o <= inst_i;
        pcplus4_o <= pcplus4_i;
    end
end

endmodule