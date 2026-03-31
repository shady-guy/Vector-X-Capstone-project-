module hazardDetectionUnit (
    input [4:0] id_ex_rd,
    input [4:0] ex_mem_rd,       
    input [31:0] if_id_inst,
    input id_ex_memRead,
    input ex_mem_memRead,         
    input branch,     
    input taken,
    input jal,        
    input jalr,           

    output reg flush_if_id,
    output reg flush_id_ex,         
    output reg wr_pc,
    output reg wr_if_id 
);

    wire [4:0] rs1 = if_id_inst[19:15];
    wire [4:0] rs2 = if_id_inst[24:20];
    
    always @(*) begin
        // default
        wr_pc       = 1;
        wr_if_id    = 1;
        flush_if_id = 0;
        flush_id_ex = 0;
        
        // flush in case of jump or branch taken
        if ((branch && taken) || jal || jalr) begin // (&& taken) is static branch prediction: always NT, saves 1 cycle penalty when branch not taken
            flush_if_id = 1; // next inst is NOP
        end
        
        // stall once when rd of n-1 ld = rs of n arith/jalr/br  - A
        // stall once when rd of n-1 arith = rs of n br          - B
        // stall once when rd of n-2 ld = rs of n br             - C
        // stall twice when rd of n-1 ld = rs of n br            - D
        
        // n is in ID stage, so n-1 is in id_ex and n-2 is from ex_mem
        if (
            (id_ex_memRead && id_ex_rd != 0 && (id_ex_rd == rs1 || id_ex_rd == rs2)) ||             //A      
            //prev==load  AND rd(prev)!=x0 AND  rd(prev) == rs(cur)
            (branch   && id_ex_rd != 0 && !id_ex_memRead && (id_ex_rd == rs1 || id_ex_rd == rs2)) ||//B
            //cur==br AND rd(prev)!=x0  AND prev!=load  AND   rd(prev) == rs(cur)
            (branch   && ex_mem_memRead && ex_mem_rd != 0 && (ex_mem_rd == rs1 || ex_mem_rd == rs2))//C
            //cur==br AND prev-1==load AND rd(prev-1)!=x0 AND rd(prev-1) == rs(cur)
            ) begin
            wr_pc       = 0;        // freeze PC
            wr_if_id    = 0;        // freeze IF/ID
            flush_id_ex = 1;        // insert NOP into ID/EX
        end
        // A + C handles D
        // A: stall once when rd of n-1 ld = rs of n br
        // ld, br becomes ld, stall, br
        // C: stall once when rd of n-2 ld = rs of n br
        // ld, stall, br becomes ld, stall, stall, br
       
    end

endmodule