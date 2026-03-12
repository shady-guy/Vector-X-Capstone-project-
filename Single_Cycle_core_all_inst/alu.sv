module alu(
    input logic [3:0]alu_ctrl,
    input logic [31:0]src1,src2,
    output logic z_flag,
    output logic [31:0] alu_rslt,
    output logic alu_lbit
);

    always_comb begin : ALU_operations
        case(alu_ctrl)
            4'd0: alu_rslt = src1 + src2;
            4'd1: alu_rslt = src1 - src2;
            4'd2: alu_rslt = src1 & src2;
            4'd3: alu_rslt = src1 | src2;
            4'd4: alu_rslt = src1 << src2;
            4'd5: alu_rslt = {31'd0, {($signed(src1) < $signed(src2)) ? 1'b1:1'b0}};
            4'd7: alu_rslt = {31'd0, {(src1) < (src2) ? 1'b1:1'b0}};
            4'd8: alu_rslt = src1 ^ src2;
            4'd9: alu_rslt = src1 >> src2;
            4'd10: alu_rslt = src1 >>> src2;
            default: alu_rslt = 32'd0;
        endcase
    end

    assign z_flag = (alu_rslt == 32'd0);
    assign alu_lbit = alu_rslt[0];

endmodule