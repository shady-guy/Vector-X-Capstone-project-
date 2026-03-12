module ctrl_unit(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic z_flag,alu_lbit,
    output logic regwrite,
    output logic alu_src,
    output logic [2:0] imm_src,
    output logic [3:0] alu_ctrl,
    output logic mem_write,
    output logic [1:0]rslt_src,
    output logic pc_src, 
    output logic [1:0]u_type_src
);

    logic [1:0]alu_op;
    logic branch;
    logic jump;
    always_comb begin : Main_Decoder
        regwrite = 0;
        alu_src  = 0;
        mem_write= 0;
        branch   = 0;
        jump     = 0;
        rslt_src = 2'd0;
        imm_src  = 3'd0;
        alu_op   = 2'd0;
        u_type_src = 2'd0;
        casez(opcode)
            7'd3: begin : I_type
                    regwrite = 1'b1;
                    imm_src = 3'd0;
                    alu_src = 1'b1;
                    mem_write = 1'b0;
                    alu_op = 2'b00;
                    rslt_src = 2'd1;
                    branch = 1'b0;
                    jump = 1'b0;
                end
            7'd35: begin : S_type
                    regwrite = 1'b0;
                    imm_src = 3'd1;
                    alu_src = 1'b1;
                    mem_write = 1'b1;
                    alu_op = 2'b00;
                    branch = 1'b0;
                    jump = 1'b0;
                    rslt_src = 2'd0;
            end
            7'd51: begin : Rtype
                    regwrite = 1'b1;
                    imm_src = 3'd1;
                    alu_src = 1'b0;
                    mem_write = 1'b0;
                    alu_op = 2'b10; 
                    rslt_src = 2'd0;
                    branch = 1'b0;
                    jump = 1'b0;
            end
            7'd99: begin : B_type
                    regwrite = 1'b0;
                    imm_src = 3'd2;
                    alu_src = 1'b0;
                    mem_write = 1'b0;
                    alu_op = 2'b01; 
                    branch = 1'b1;
                    jump = 1'b0; 
                    rslt_src = 2'd0;   
            end
            7'd19: begin : addi
                    regwrite = 1'b1;
                    imm_src = 3'd0;
                    mem_write = 1'b0;
                    alu_src = 1'b1;
                    alu_op = 2'b10;
                    rslt_src = 2'd0;
                    branch = 1'b0;
                    jump = 1'b0;
            end
            7'b110?111: begin : jal_jalr
                    regwrite = 1'b1;
                    imm_src = 3'd3;
                    mem_write = 1'b0;
                    rslt_src = 2'b10;
                    branch = 1'b0;
                    jump = 1'b1;
                    case(opcode[3])
                        1'b0: begin //jalr
                            imm_src = 3'd0;
                            u_type_src = 2'd2;
                        end 
                        1'b1: begin //jal
                            imm_src = 3'd3;
                            u_type_src = 2'd0;
                        end
                    endcase
            end
            7'b0?10111: begin : u_type
                    regwrite = 1'b1;
                    imm_src = 3'd4;
                    mem_write = 1'b0;
                    rslt_src = 2'd3;
                    branch = 1'b0;
                    jump = 1'b0;
                    case(opcode[5]) 
                        1'b0: u_type_src = 2'd0;   //auipc
                        1'b1: u_type_src = 2'd1;   //lui
                    endcase
            end
            default: begin
                    regwrite = 1'b1;
                    imm_src = 3'd0;
                    alu_src = 1'b1;
                    mem_write = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                    jump = 1'b0;
                end     
        endcase
    end

    //alu decoder
    always_comb begin : ALU_Decoder
        case(alu_op) 
            2'b00: alu_ctrl = 4'd0; //lw and sw
            2'b01: begin : b_type
                case(funct3)
                    3'd0: alu_ctrl = 4'd1;
                    3'd4: alu_ctrl = 4'd5;            
                    3'd5: alu_ctrl = 4'd5;                        
                    3'd6: alu_ctrl = 4'd7;            
                    3'd7: alu_ctrl = 4'd7;            
                endcase
            end
            2'b10: begin : r_type_alu_imm_type
                    case(funct3)
                        3'd0: begin
                            if(opcode == 7'd19) alu_ctrl = 4'd0;
                            else alu_ctrl = funct7[5] ? 4'd1:4'd0;
                        end 
                        3'd1: alu_ctrl = 4'd4;
                        3'd2: alu_ctrl = 4'd5;
                        3'd3: alu_ctrl = 4'd7;
                        3'd4: alu_ctrl = 4'd8;
                        3'd5: alu_ctrl = funct7[5] ? 4'd10:4'd9;
                        3'd6: alu_ctrl = 4'd3;
                        3'd7: alu_ctrl = 4'd2;
                        default: alu_ctrl = 4'bxxx;
                    endcase
                end
            default: alu_ctrl = 4'bxxxx;
        endcase
    end

    //branch decoder
    logic bch;
    always_comb begin : branches
        case(funct3)
            3'd0: bch = z_flag & branch;
            3'd1: bch = (!z_flag) & branch;
            3'd4,3'd6: bch = (alu_lbit) & branch;
            3'd5,3'd7: bch = (!alu_lbit) & branch;
            default bch = 1'b0;
        endcase
    end

    assign pc_src = bch | jump;
endmodule