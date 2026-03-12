module signext (
    input logic [31:7]instr,
    input logic [2:0]imm_src,
    output logic [31:0]ext_imm
);

    always_comb begin : imm_gen 
        case(imm_src)
            3'b000: ext_imm = {{20{instr[31]}},instr[31:20]};   //i type
            3'b001: ext_imm = {{20{instr[31]}},instr[31:25],instr[11:7]};   //s type
            3'b010: ext_imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};     //b type
            3'b011: ext_imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};   //j type
            3'b100: ext_imm = {instr[31:12],{12{1'b0}}};    //u type
            default: ext_imm = 32'd0;   
        endcase
    end
    
endmodule   