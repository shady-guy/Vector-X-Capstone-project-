`timescale 1ns/1ps

module Control(
    input [6:0] opcode,
    output reg branch,memread,memreg,memwrite,alusrc,regwrite,
    output reg [1:0] aluop
    );
    
    always@(*)
    begin
    case(opcode)
    7'b0110011: begin // R-type
        alusrc=0;
        memreg=0;
        regwrite=1;
        memread=0;
        memwrite=0;
        branch=0;
        aluop = 2'b10;
        end
    7'b0000011: begin //lw
        alusrc=1;
        memreg=1;
        regwrite=1;
        memread=1;
        memwrite=0;
        branch=0;
        aluop = 2'b00;
        end
    7'b0100011: begin //sw
        alusrc=1;
        memreg=1'b0;
        regwrite=0;
        memread=0;
        memwrite=1;
        branch=0;
        aluop = 2'b00;
        end
    7'b0010011: begin // i-type add
        regwrite = 1;
        alusrc = 1;
        aluop = 2'b10;
        end
    7'b1100011: begin //beq
        alusrc=0;
        memreg=1'b0;
        regwrite=0;
        memread=0;
        memwrite=0;
        branch=1;
        aluop = 2'b01;
        end
    default: begin
        alusrc=0;
        memreg=0;
        regwrite=0;
        memread=0;
        memwrite=0;
        branch=0;
        aluop = 2'b00;
        end
        endcase
    end
endmodule