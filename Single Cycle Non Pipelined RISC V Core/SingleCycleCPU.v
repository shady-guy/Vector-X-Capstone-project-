module SingleCycleCPU (
    input clk,
    input start
    
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

wire [31:0] nextpc;
wire [31:0] pcout;
PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(nextpc), // received from pc_mux
    .pc_o(pcout)   // pc pointing to current instruction
);

wire [31:0] pcplus4;
Adder m_Adder_1(  // normal next value of pc (in case of no branch or jump)
    .a(pcout),   
    .b(32'd4),
    .sum(pcplus4)
);

wire [31:0] instruction;
InstructionMemory m_InstMem( // reading instruction from instruction memory
    .readAddr(pcout),
    .inst(instruction)
);

wire branch;
wire memRead;
wire memtoReg;
wire [1:0] ALUOp;
wire memWrite;
wire ALUSrc;
wire regWrite;
Control m_Control( // extracting opcode from instruction and generating control signals accordingly
    .opcode(instruction[6:0]), 
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite)
);

wire [31:0] rs2content;
wire [31:0] rs1content;
wire [31:0] rdcontent;
Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite),
    .readReg1(instruction[19:15]), // rs1
    .readReg2(instruction[24:20]), // rs2
    .writeReg(instruction[11:7]),  // rd
    .writeData(rdcontent),
    .readData1(rs1content),
    .readData2(rs2content)
);

wire [31:0] immval; // extracting immediate value based on type of instruction
ImmGen #(.Width(32)) m_ImmGen(
    .inst(instruction),
    .imm(immval)
);

wire [31:0] immx2; 
ShiftLeftOne m_ShiftLeftOne( // for beq instruction
    .i(immval),
    .o(immx2)
);

wire [31:0] pcjumploc; 
Adder m_Adder_2( // after beq where to jump
    .a(pcout),
    .b(immx2),
    .sum(pcjumploc)
);

wire zeroflag;
Mux2to1 #(.size(32)) m_Mux_PC( // decides next pc
    .sel(branch & zeroflag),
    .s0(pcplus4),
    .s1(pcjumploc),
    .out(nextpc)
);

wire [31:0] aluip2;
Mux2to1 #(.size(32)) m_Mux_ALU( // decides if second i/p to ALU is rs2 or imm value
    .sel(ALUSrc),
    .s0(rs2content),
    .s1(immval),
    .out(aluip2)
);

wire [3:0] ALUCtl;
ALUCtrl m_ALUCtrl( // controls ALU according to funct3 and funct7
    .ALUOp(ALUOp),
    .funct7(instruction[31:25]),
    .funct3(instruction[14:12]),
    .ALUCtl(ALUCtl)
);

wire [31:0] ALUOut;
ALU m_ALU(   // ALU
    .ALUCtl(ALUCtl),
    .A(rs1content),
    .B(aluip2),
    .ALUOut(ALUOut),
    .zero(zeroflag)
);

wire [31:0] datafrommem;
DataMemory m_DataMemory( // to read from and write to memory
    .rst(start),
    .clk(clk),
    .memWrite(memWrite),
    .memRead(memRead),
    .address(ALUOut),
    .writeData(rs2content),
    .readData(datafrommem)
);

Mux2to1 #(.size(32)) m_Mux_WriteData( // to select whether rd should be written with ALU result or from memory
    .sel(memtoReg),
    .s0(ALUOut),
    .s1(datafrommem),
    .out(rdcontent)
);

endmodule
