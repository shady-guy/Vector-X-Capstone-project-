module Control (
    input  [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite
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
            end
            7'b0010011: begin // I TYPE
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b11;
                memWrite = 0;
                ALUSrc = 1;
                regWrite = 1;
            end
            7'b0100011: begin // SW
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00;
                memWrite = 1;
                ALUSrc = 1;
                regWrite = 0;
            end
            7'b0110011: begin // R TYPE
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b10;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 1;
            end
            7'b1100011: begin // BEQ
                branch = 1;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b01;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 0;
            end
            default: begin 
                branch = 0;
                memRead = 0;
                memtoReg = 0;
                ALUOp = 2'b00;
                memWrite = 0;
                ALUSrc = 0;
                regWrite = 0;
            end
            // ALUOp is predefined: 00 for lw, sw; 01 for beq and 10 for R and I type
            // Branch = 1 only for beq; 0 for all else
            // ALUSrc = 1 (imm val / offset) for I and lw, sw and 0 (from reg) for R and beq
            // MemRead = 1 only for lw
            // MemWrite = 1 only for sw
            // RegWrite = 0 only for beq and sw
            // MemToReg = 1 only for lw, for others ALU result to reg (so 0)
            
        endcase
     end
endmodule




