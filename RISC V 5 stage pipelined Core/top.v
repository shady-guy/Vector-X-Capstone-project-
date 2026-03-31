module FullyPipelinedCore (
    input clk,
    input start,
    output wire dummy_out
);
// When input start is zero, cpu should reset
// When input start is high, cpu start running
// IF stage
wire [31:0] pcout, if_pcplus4, if_instruction;

// ID stage
wire [31:0] id_pc, id_pcplus4, id_immval, id_immx2;
wire [31:0] id_rs1content, id_rs2content;
wire [31:0] pcjumploc, pcbasednextpc;
wire id_branch, id_memRead, id_memtoReg, id_memWrite;
wire id_ALUSrc, id_regWrite, id_jal, id_jalr;
wire [3:0] id_ALUCtl;
wire [1:0] bc;
wire eq, lt, eqorlt;
wire taken;

// EX stage
wire [31:0] ex_pc, ex_pcplus4, ex_rdata1, ex_rdata2;
wire [31:0] ex_immval, ex_ALUOut;
wire [31:0] aluip1, aluip2, ex_aluip2, ex_storedata;
wire [4:0] ex_rd, ex_rs1, ex_rs2;
wire ex_regWrite, ex_memtoReg, ex_memWrite, ex_memRead;
wire ex_branch, ex_ALUSrc, ex_jal, ex_jalr;
wire [3:0] ex_ALUCtl;
wire [1:0] ALUSrc1, ALUSrc2;

// MEM stage
wire [31:0] mem_ALUout, mem_rdata2, mem_pcplus4;
wire [31:0] mem_readData;
wire [4:0] mem_rd, mem_rs2;
wire mem_regWrite, mem_memtoReg, mem_memWrite, mem_memRead;
wire mem_jal, mem_jalr;

// WB stage
wire [31:0] wb_ALUout, wb_readData, wb_pcplus4;
wire [31:0] regcontent, rdcontent;
wire [4:0] wb_rd;
wire wb_regWrite, wb_memtoReg, wb_jal, wb_jalr;

// Hazard/control
wire [31:0] nextpc;
wire wr_pc, wr_if_id, flush_if_id, flush_id_ex;

PC m_PC(
    .clk(clk),
    .rst(start),
    .wr_pc(wr_pc),
    .pc_i(nextpc), // received from pc_mux
    .pc_o(pcout)   // pc pointing to current instruction
);

Adder m_Adder_1(  // normal next value of pc (in case of no branch or jump)
    .a(pcout),   
    .b(32'd4),
    .sum(if_pcplus4)
);

wire [31:0] id_inst;
InstructionMemory m_InstMem( // reading instruction from instruction memory
    .readAddr(pcout),
    .inst(if_instruction),
    .clk(clk)
);

if_id_reg m_if_id_reg(
    .rst(start),
    .clk(clk),
    .pc_i(pcout),
    .inst_i(if_instruction),
    .pc_o(id_pc),
    .inst_o(id_inst),
    .flush_if_id(flush_if_id),
    .wr_if_id(wr_if_id),
    .pcplus4_i(if_pcplus4),
    .pcplus4_o(id_pcplus4)
);

Control m_Control( // extracting opcode from instruction and generating control signals accordingly
    .opcode(id_inst[6:0]), 
    .branch(id_branch),
    .memRead(id_memRead),
    .memtoReg(id_memtoReg),
    .memWrite(id_memWrite),
    .ALUSrc(id_ALUSrc),
    .regWrite(id_regWrite),
    .jal(id_jal),
    .jalr(id_jalr),
    .funct7(id_inst[31:25]),
    .funct3(id_inst[14:12]),
    .ALUCtl(id_ALUCtl),
	.branchcontrol(bc)
);

wire [31:0] reg_readData1, reg_readData2;
Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(wb_regWrite),
    .readReg1(id_inst[19:15]), // rs1
    .readReg2(id_inst[24:20]), // rs2
    .writeReg(wb_rd),  // rd
    .writeData(rdcontent),
    .readData1(reg_readData1),   
    .readData2(reg_readData2)     
);
assign id_rs1content = (wb_regWrite && wb_rd == id_inst[19:15] && wb_rd != 0) 
                       ? rdcontent : reg_readData1;
assign id_rs2content = (wb_regWrite && wb_rd == id_inst[24:20] && wb_rd != 0) 
                       ? rdcontent : reg_readData2;
// reading from a reg that is being written to in the same cycle? read directly - forwarding unit for inst mem

// extracting immediate value based on type of instruction
ImmGen #(.Width(32)) m_ImmGen(
    .inst(id_inst),
    .imm(id_immval)
);

ShiftLeftOne m_ShiftLeftOne( // for branch and jump instruction
    .i(id_immval),
    .o(id_immx2)
);

Adder m_Adder_2( // after branch where to jump
    .a(id_pc),
    .b(id_immx2),
    .sum(pcjumploc)
);

wire [1:0] cmpSrc1, cmpSrc2;
wire [31:0] cmpA, cmpB;

forwardingUnit m_fwd_unit_cmp( // forwarding unit for comparator
    .rs1(id_inst[19:15]),
    .rs2(id_inst[24:20]),
    .ex_mem_rd(mem_rd),
    .ex_mem_regwrite(mem_regWrite),
    .mem_wb_rd(wb_rd),
    .mem_wb_regwrite(wb_regWrite),
    .Src1(cmpSrc1),
    .Src2(cmpSrc2)
);

Mux3to1 #(.size(32)) m_Mux_CmpSrc1( // forwarding mux for comparator
    .sel(cmpSrc1),
    .s0(id_rs1content),
    .s1(rdcontent),
    .s2(mem_ALUout),
    .out(cmpA)
);

Mux3to1 #(.size(32)) m_Mux_CmpSrc2( // forwarding mux for comparator
    .sel(cmpSrc2),
    .s0(id_rs2content),
    .s1(rdcontent),
    .s2(mem_ALUout),
    .out(cmpB)
);

comparator m_cmp( // comparator for branch resolution
    .A(cmpA),
    .B(cmpB),
    .eq(eq),
    .lt(lt)
);

assign eqorlt = bc[1]?lt:eq;

assign taken = id_branch & (bc[0]^eqorlt); //if (branch inst AND related condition)
Mux2to1 #(.size(32)) m_Mux_PC1( // decides next pc in case of not jalr
    .sel(taken | id_jal), // if branch taken OR jal, select pcbasednextpc, else pc+4
    .s0(if_pcplus4),
    .s1(pcjumploc),
    .out(pcbasednextpc)
); // explanation of condition: for beq, blt take eq / lt as it is (branchcontrol[0]=0), 
   // for bne, bge, complement eq / lt

hazardDetectionUnit m_hz_unit(
    .id_ex_rd(ex_rd),
    .ex_mem_rd(mem_rd),       
    .if_id_inst(id_inst),
    .id_ex_memRead(ex_memRead),
    .ex_mem_memRead(mem_memRead),         
    .branch(id_branch),     
    .taken(taken),
    .jal(id_jal),        
    .jalr(id_jalr),           
    .flush_if_id(flush_if_id),
    .flush_id_ex(flush_id_ex),         
    .wr_pc(wr_pc),
    .wr_if_id(wr_if_id) 
);

id_ex_reg m_id_ex_reg (
    .clk               (clk),
    .rst               (start),
    .regWrite_i        (id_regWrite),
    .memtoReg_i        (id_memtoReg),
    .memWrite_i        (id_memWrite),
    .memRead_i         (id_memRead),
    .ALUSrc_i          (id_ALUSrc),
    .ALUCtl_i          (id_ALUCtl),
    .pc_i              (id_pc),
    .rdata1_i          (id_rs1content),
    .rdata2_i          (id_rs2content),
    .imm_i             (id_immval),
    .rd_i              (id_inst[11:7]),
    .rs1_i             (id_inst[19:15]),
    .rs2_i             (id_inst[24:20]),
    .regWrite_o        (ex_regWrite),
    .memtoReg_o        (ex_memtoReg),
    .memWrite_o        (ex_memWrite),
    .memRead_o         (ex_memRead),
    .ALUSrc_o          (ex_ALUSrc),
    .ALUCtl_o          (ex_ALUCtl),
    .pc_o              (ex_pc),
    .rdata1_o          (ex_rdata1),
    .rdata2_o          (ex_rdata2),
    .imm_o             (ex_immval),
    .rd_o              (ex_rd),
    .rs1_o             (ex_rs1),
    .rs2_o             (ex_rs2),
    .flush_id_ex       (flush_id_ex),
    .jal_i(id_jal),
    .jalr_i(id_jalr),
    .jalr_o(ex_jalr),
    .jal_o(ex_jal),
    .pcplus4_i(id_pcplus4),
    .pcplus4_o(ex_pcplus4)
);

Mux2to1 #(.size(32)) m_Mux_PC( // decides next pc
    .sel(ex_jalr), // if jalr, select ALUOut which is rs1content+immval, else select previous mux output
    .s0(pcbasednextpc),
    .s1(ex_ALUOut),
    .out(nextpc)
);

forwardingUnit m_fwd_unit_alu( // forwarding unit for ALU
    .rs1(ex_rs1),
    .rs2(ex_rs2),
    .ex_mem_rd(mem_rd),
    .ex_mem_regwrite(mem_regWrite),
    .mem_wb_rd(wb_rd),
    .mem_wb_regwrite(wb_regWrite),
    .Src1(ALUSrc1),
    .Src2(ALUSrc2)
);

Mux3to1 #(.size(32)) m_Mux_ALUSrc1( // forwarding mux for ALU 1st operand
    .sel(ALUSrc1),
    .s0(ex_rdata1),
    .s1(rdcontent),
    .s2(mem_ALUout),
    .out(aluip1)
);

wire [31:0] ex_aluip2_forwarded;
Mux3to1 #(.size(32)) m_Mux_ALUSrc2( // forwarding mux for ALU 2nd operand
    .sel(ALUSrc2),
    .s0(ex_rdata2),
    .s1(rdcontent),
    .s2(mem_ALUout),
    .out(ex_aluip2_forwarded)
);

Mux2to1 #(.size(32)) m_Mux_ALU( // decides if second i/p to ALU is 2nd operand or imm value - meaningful in case of sw
    .sel(ex_ALUSrc),
    .s0(ex_aluip2_forwarded),
    .s1(ex_immval),
    .out(ex_aluip2)
);

ALU m_ALU(   // ALU
    .ALUCtl(ex_ALUCtl),
    .A(aluip1),
    .B(ex_aluip2),
    .ALUOut(ex_ALUOut)
);

ex_mem_reg m_ex_mem_reg (
    .clk               (clk),
    .rst               (start),
    .regWrite_i        (ex_regWrite),
    .memtoReg_i        (ex_memtoReg),
    .memWrite_i        (ex_memWrite),
    .memRead_i         (ex_memRead),
    .ALUResult_i       (ex_ALUOut),
    .rdata2_i          (ex_rdata2),    
    .rd_i              (ex_rd),
    .rs2_i(ex_rs2),
    .rs2_o(mem_rs2),
    .regWrite_o        (mem_regWrite),
    .memtoReg_o        (mem_memtoReg),
    .memWrite_o        (mem_memWrite),
    .memRead_o         (mem_memRead),
    .ALUResult_o       (mem_ALUout), 
    .rdata2_o          (mem_rdata2),
    .rd_o              (mem_rd),
    .jal_i(ex_jal),
    .jalr_i(ex_jalr),
    .jal_o(mem_jal),
    .jalr_o(mem_jalr),
    .pcplus4_i(ex_pcplus4),
    .pcplus4_o(mem_pcplus4)
);

wire [31:0] mem_writedata;
assign mem_writedata = (wb_regWrite && wb_rd != 0 && wb_rd == mem_rs2) // this is like forwarding unit for data mem
                       ? rdcontent : mem_rdata2;

DataMemory m_DataMemory( // to read from and write to memory
    .rst(start),
    .clk(clk),
    .memWrite(mem_memWrite),
    .memRead(mem_memRead),
    .address(mem_ALUout),
    .writeData(mem_writedata),
    .readData(mem_readData)
);

mem_wb_reg m_mem_wb_reg (
    .clk            (clk),
    .rst            (start),
    .regWrite_i     (mem_regWrite),
    .memtoReg_i     (mem_memtoReg),
    .ALUOut_i       (mem_ALUout), 
    .readData_i     (mem_readData),  
    .rd_i           (mem_rd),
    .regWrite_o     (wb_regWrite),  
    .memtoReg_o     (wb_memtoReg),  
    .ALUResult_o    (wb_ALUout),
    .readData_o     (wb_readData),
    .rd_o           (wb_rd),
    .jal_i(mem_jal),
    .jalr_i(mem_jalr),
    .jal_o(wb_jal),
    .jalr_o(wb_jalr),
    .pcplus4_i(mem_pcplus4),
    .pcplus4_o(wb_pcplus4)
);

Mux2to1 #(.size(32)) m_Mux_WriteData( // to select what should be written to reg unit: ALU result or from memory
    .sel(wb_memtoReg),
    .s0(wb_ALUout),
    .s1(wb_readData),
    .out(regcontent)
);


Mux2to1 #(.size(32)) m_Mux_RegContent( // to select whether rd should be written with above result or pcplus4 (in case of jalr)
    .sel(wb_jal | wb_jalr),
    .s0(regcontent),
    .s1(wb_pcplus4),
    .out(rdcontent)
);

assign dummy_out = pcout;

endmodule
