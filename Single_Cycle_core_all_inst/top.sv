module top #(
    parameter IMEM_WORDS  = 64,
    parameter DMEM_WORDS  = 64,
    parameter IMEM_INIT   = "imem.hex",
    parameter DMEM_INIT   = "dmem.hex"
)(
    input logic clk,
    input logic rst
);

    logic [31:0] PC, PC_next, PC_plus4; 

    logic [31:0] instr;
    logic [6:0]  opcode;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic regwrite, alu_src, mem_write, pc_src;
    logic [31:0] ext_imm; 
    logic [2:0]  imm_src;
    logic [3:0]  alu_ctrl;
    logic [1:0]  rslt_src, u_type_src;
    logic z_flag, alu_lbit;
    logic misalign;

    logic [31:0] rd1, rd2;
    logic [31:0] alu_src_b;
    logic [31:0] alu_rslt;
    logic [31:0] sec_add_in;
    logic [31:0] sec_add_out;
    logic [31:0] mem_rd;
    logic [31:0] load_data;
    logic [31:0] wb_data;

    assign opcode   = instr[6:0];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];

    assign PC_plus4 = PC + 32'd4;

    //pc next mux: 00 = +4, 01 = branch/jal and jalr type
    always_comb begin
        if(!pc_src)
            PC_next = PC_plus4;
        else
            PC_next = sec_add_out;
    end

    // pc register
    pc_reg u_pc_reg (
        .clk     (clk),
        .rst     (rst),
        .PC_next (PC_next),
        .PC      (PC)
    );

    // instruction memory
    imem #(.WORDS(IMEM_WORDS), .mem_init(IMEM_INIT)) u_imem (
        .addr (PC),
        .rd   (instr)
    );

    // register file
    regfile u_regfile (
        .clk      (clk),
        .rst      (rst),
        .addr1    (rs1_addr),
        .addr2    (rs2_addr),
        .addr3    (rd_addr),
        .rd1      (rd1),
        .rd2      (rd2),
        .wr_data  (wb_data),
        .regwrite (regwrite)
    );

    // sign extender
    signext u_signext (
        .instr   (instr[31:7]),
        .imm_src (imm_src),
        .ext_imm (ext_imm)
    );

    // alu src mux: 0 = rd2, 1 = ext_imm
    mux2 u_alu_src_mux (
        .d0  (rd2),
        .d1  (ext_imm),
        .sel (alu_src),
        .y   (alu_src_b)
    );

    // alu
    alu u_alu (
        .alu_ctrl (alu_ctrl),
        .src1     (rd1),
        .src2     (alu_src_b),
        .z_flag   (z_flag),
        .alu_rslt (alu_rslt),
        .alu_lbit (alu_lbit)
    );

    // second adder src mux: 00 = 32'b0, 01 = PC, 10 = rd1
    mux3 u_sec_add_src_mux (
        .d0  (PC),
        .d1  (32'd0),
        .d2  (rd1),
        .sel (u_type_src),
        .y   (sec_add_in)
    );

    // second adder: sec_add_in + ext_imm
    pc_adder u_sec_adder (
        .PC     (sec_add_in),
        .b      (ext_imm),
        .PC_nxt (sec_add_out)
    );

    // data memory
    memory #(.WORDS(DMEM_WORDS), .mem_init(DMEM_INIT)) u_dmem (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (mem_write),
        .funct3   (funct3),
        .addr     (alu_rslt),
        .wr_data  (rd2),
        .rd       (mem_rd),
        .misalign (misalign)
    );

    // load extend
    load_extract u_load_extend (
        .raw_data   (mem_rd),
        .funct3     (funct3),
        .byte_offset(alu_rslt[1:0]),
        .load_data  (load_data)
    );

    // write-back mux: 00=alu_rslt, 01=load_data, 10=sec_add_out, 11=sec_add_out
    mux4 u_wb_mux (
        .d0  (alu_rslt),
        .d1  (load_data),
        .d2  (PC_plus4),
        .d3  (sec_add_out),
        .sel (rslt_src),
        .y   (wb_data)
    );

    // control unit
    ctrl_unit u_ctrl (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .z_flag     (z_flag),
        .alu_lbit   (alu_lbit),
        .regwrite   (regwrite),
        .alu_src    (alu_src),
        .imm_src    (imm_src),
        .alu_ctrl   (alu_ctrl),
        .mem_write  (mem_write),
        .rslt_src   (rslt_src),
        .pc_src     (pc_src),
        .u_type_src (u_type_src)
    );

endmodule
