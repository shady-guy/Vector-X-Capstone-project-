module ALU (
    input [3:0] ALUCtl,
    input [31:0] A,B,
    output reg [31:0] ALUOut,
    output reg zero,
    output reg carry,
    output reg negative,
    output reg overflow
);
    // ALU has two operand, it execute different operator based on ALUctl wire 
    // output zero is for determining taking branch or not 

   
    always @(*) begin 
        case (ALUCtl)
            4'b0000: {carry, ALUOut} = A + B;            // ADD, ADDI, LW, SW
            4'b0001: ALUOut = A << B;                    // SLL, SLLI
            4'b0010: ALUOut = ($signed(A) < $signed(B)); // SLT, SLTI, BLT, BGE
            4'b0011: ALUOut = (A < B);                   // SLTU, SLTUI
            4'b0100: ALUOut = A ^ B;                     // XOR, XORI
            4'b0101: ALUOut = A >> B;                    // SRL, SRLI
            4'b0110: ALUOut = A | B;                     // OR, ORI         
            4'b0111: ALUOut = A & B;                     // AND, ANDI    
            4'b1000: {carry, ALUOut} = A - B;            // SUB, BEQ, BNE
            4'b1101: ALUOut = $signed(A) >>> B;          // SRA, SRAI 
            default: ALUOut = 0;
        endcase
        zero = (ALUOut == 0);                              // zero flag
        negative = ALUOut[31];                             // negative flag
        overflow = (A[31]==B[31] ? A[31]:0) ^ ALUOut[31];  // overflow flag
    end
    
endmodule

