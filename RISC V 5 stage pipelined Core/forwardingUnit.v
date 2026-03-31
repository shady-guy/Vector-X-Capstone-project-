module forwardingUnit(
        input [4:0] rs1, // id_ex for ALU, from inst mem for Comparator
        input [4:0] rs2,
        
        input [4:0] ex_mem_rd,
        input ex_mem_regwrite,
        
        input [4:0] mem_wb_rd,
        input mem_wb_regwrite,

        output reg [1:0] Src1,
        output reg [1:0] Src2
    );
    
    // ALU Src muxes are 
    // 0:rscontent/imm from ID - use when no forwarding
    // 1:datamem (rd of n-1 ld is same as rs) or ALUres (when rd of n-2 arith is same as rs) from MEM/WB 
    // bcoz of stall, n-1th ld behaves like n-2th ld
    // 2:ALUres from EX/MEM - use when rd of n-1 arith is same as rs
    
    // comparator Src muxes are 
    // 0:rscontent from reg unit - use when no forwarding
    // 1:datamem (rd of n-2 ld is same as rs) or ALUres (when rd of n-3 arith is same as rs) from MEM/WB
    // bcoz of stall, n-2th ld behaves like n-3th ld
    // 2:ALUres from EX/MEM - use when rd of n-2 arith is same as rs
    
    always@(*) begin
        if (ex_mem_regwrite && ex_mem_rd != 0 && ex_mem_rd == rs1) // rd of n-1 same as rs1 of n
            Src1 = 2'b10;
        else if (mem_wb_regwrite && mem_wb_rd != 0 && mem_wb_rd == rs1) // rd of n-2 same as rs1 of n
            Src1 = 2'b01;
        else
            Src1 = 2'b00;

        if (ex_mem_regwrite && ex_mem_rd != 0 && ex_mem_rd == rs2) // rd of n-1 same as rs2 of n
            Src2 = 2'b10;
        else if (mem_wb_regwrite && mem_wb_rd != 0 && mem_wb_rd == rs2) // rd of n-2 same as rs2 of n
            Src2 = 2'b01;
        else
            Src2 = 2'b00;
    end
    // regwrite means inst was ld or arith
    // rd != 0 check is there to avoid writing to x0
    
    // ALU: ex_mem is n-1th inst and mem_wb is n-2th inst
    // Cmp: ex_mem is n-2th inst and mem_wb is n-3th inst
    
    
endmodule
