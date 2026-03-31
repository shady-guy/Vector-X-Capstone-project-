module mem_wb_reg(
    input clk,
    input rst,

    //to WB 
    input regWrite_i,
    input memtoReg_i,

    //data signals from MEM 
    input [31:0] ALUOut_i,
    input [31:0] readData_i,
    input [4:0] rd_i,
    input jal_i,
    input jalr_i,

    //outputs to WB stage
    output reg regWrite_o,
    output reg memtoReg_o,
    output reg [31:0] ALUResult_o,
    output reg [31:0] readData_o,
    output reg [4:0] rd_o,
    output reg jal_o,
    output reg jalr_o,
    input [31:0] pcplus4_i,
    output reg [31:0] pcplus4_o
);

always @(posedge clk) begin
    if (~rst) begin
        regWrite_o <= 1'b0;
        memtoReg_o <= 1'b0;
        ALUResult_o <= 32'b0;
        readData_o <= 32'b0;
        rd_o <= 5'b0;
        jal_o <= 0;
        jalr_o <= 0;
        pcplus4_o <= 0;
    end
    else begin
        regWrite_o <= regWrite_i;
        memtoReg_o <= memtoReg_i;
        ALUResult_o <= ALUOut_i;
        readData_o <= readData_i;
        rd_o <= rd_i;
        jal_o <= jal_i;
        jalr_o <= jalr_i;
        pcplus4_o <= pcplus4_i;
    end
end
endmodule