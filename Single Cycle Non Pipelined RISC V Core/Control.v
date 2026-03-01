module Control (
    input  [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite,
    output reg jal,
    output reg jalr
);


    always@(*) begin
        case(opcode)
            7'b0000011: begin // LW
                branch = 0;
                memRead = 1;
                memtoReg = 1;
                ALUOp = 2'b00;
                memWrite = 0;
                ALUSrc = 1;
                regWrite = 1;
                jal = 0;
                jalr = 0;
            end
            7'b0010011: begin // I TYPE
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b11;
                memWrite = 0;
                ALUSrc = 1;
                regWrite = 1;
                jal = 0;
                jalr = 0;
            end
            7'b0100011: begin // SW
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00;
                memWrite = 1;
                ALUSrc = 1;
                regWrite = 0;
                jal = 0;
                jalr = 0;
            end
            7'b0110011: begin // R TYPE
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b10;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 1;
                jal = 0;
                jalr = 0;
            end
            7'b1100011: begin // BEQ, BNE, BLT, BGE
                branch = 1;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b01;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 0;
                jal = 0;
                jalr = 0;
            end
            7'b1100111: begin // JALR
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00; 
                memWrite = 0;
                ALUSrc = 1;
                regWrite = 1; // to write pcplus4
                jal = 0;
                jalr = 1;
            end
            7'b1101111: begin // JAL
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00; // don't care
                memWrite = 0;
                ALUSrc = 0; // don't care
                regWrite = 1; // to write pcplus4
                jal = 1;
                jalr = 0;
            end
            default: begin 
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 0;
                jal = 0;
                jalr = 0;
            end
            // ALUOp is predefined: 00 for lw, sw (add); 01 for branch (sub or slt) and 10 for R and I type (depends on functs)
            // Branch = 1 only for branch insts; 0 for all else
            // ALUSrc = 1 (imm val / offset) for jalr and I and lw, sw and 0 (from reg) for R and branch
            // MemRead = 1 only for lw
            // MemWrite = 1 only for sw
            // RegWrite = 0 only for branch and sw
            // MemToReg = 1 only for lw, for others ALU result to reg (so 0)
            
        endcase
     end
endmodule




