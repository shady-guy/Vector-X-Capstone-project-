// Vector Datapath
// Instantiates and connects:
// vector_register_file, VALU, vector_lsu, vector_config
// Follows the block diagram: regfile -> VALU/LSU -> memtoreg mux -> regfile write

module vector_datapath
import vector_pkg::*;
(
    input  logic clk,
    input  logic rst,

    // Instruction in — fields decoded here and by controller
    input  logic [31:0] instruction,

    // Control signals from vector_controller
    input  logic                 regwrite,
    input  vector_opcode_t       alu_op,
    input  vector_opcode_t       lsu_op,
    input  vector_mem_mode_t     mode,
    input  logic                 lsu_en,
    input  logic                 memtoreg,

    // Config unit control (from controller)
    input  logic                 cfg_write,
    input  logic                 cfg_sel_vl,
    input  logic                 cfg_sel_sew,
    input  logic [31:0]          cfg_data,      // from scalar core / instruction imm

    // Data memory interface (driven by LSU)
    output logic [31:0]          mem_addr,
    output logic                 mem_req,
    output logic                 mem_read,
    output logic                 mem_write,
    output logic [ELEN-1:0]      mem_wdata,
    input  logic                 mem_valid,
    input  logic [ELEN-1:0]      mem_rdata,

    // LSU done flag (useful for stalling top/scalar core later)
    output logic                 lsu_done
);

    // Instruction field decode
    // [31:28] op | [27:23] rd | [22:18] rs1 | [17:13] rs2 | [10:0] imm
    logic [4:0]  rd, rs1, rs2;
    logic [10:0] imm;
    assign rd  = instruction[27:23];
    assign rs1 = instruction[22:18];
    assign rs2 = instruction[17:13];
    assign imm = instruction[10:0];

    // Config Unit — provides vl, sew, epv, lane_active
    logic [31:0]        vl, sew, epv;
    logic [LANES-1:0]   lane_active;

    vector_config cfg_unit (
        .clk         (clk),
        .rst         (rst),
        .cfg_write   (cfg_write),
        .cfg_data    (cfg_data),
        .cfg_sel_vl  (cfg_sel_vl),
        .cfg_sel_sew (cfg_sel_sew),
        .vl          (vl),
        .sew         (sew),
        .epv         (epv),
        .lane_active (lane_active)
    );

    // Vector Register File
    logic [VLEN-1:0] read_data1, read_data2;
    logic [VLEN-1:0] write_data;

    vector_register_file vrf (
        .clk      (clk),
        .rst      (rst),
        .addr1    (rs1),
        .addr2    (rs2),
        .rd1      (read_data1),
        .rd2      (read_data2),
        .addr3    (rd),
        .wr_data  (write_data),
        .regwrite (regwrite)
    );

    // VALU — uses read_data1 as vs1, read_data2 as vs2
    // vl truncated to $clog2(LANES) bits for lane masking
    logic [VLEN-1:0]          alu_result;
    logic [$clog2(LANES+1)-1:0] vl_lanes; // 4 bits, can hold 0-8
    assign vl_lanes = vl[$clog2(LANES+1)-1:0];

    VALU valu (
        .op  (alu_op),
        .vs1 (read_data1),
        .vs2 (read_data2),
        .vl  (vl_lanes),
        .vd  (alu_result)
    );
    // LSU — base_addr from lower 32 bits of read_data1 (scalar addr)
    //       stride from sign-extended immediate
    //       index_vector from read_data2
    //       store_data from read_data1

    logic [VLEN-1:0] load_data;
    logic [31:0]     stride_val;
    assign stride_val = {{21{imm[10]}}, imm};  // sign-extend 11-bit imm

    vector_lsu lsu (
        .clk          (clk),
        .rst          (rst),
        .mode         (mode),
        .op           (lsu_op),
        .vl           (vl[15:0]),
        .base_addr    (read_data1[31:0]),     // lower word of vs1 = base address
        .stride       (stride_val),
        .index_vector (read_data2),           // vs2 = index vector
        .store_data   (read_data2),           // vs2 = data to store
        .load_data    (load_data),
        .mem_addr     (mem_addr),
        .mem_req      (mem_req),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .mem_wdata    (mem_wdata),
        .mem_valid    (mem_valid),
        .mem_rdata    (mem_rdata),
        .done         (lsu_done)
    );

    // Writeback mux (memtoreg): 0 = ALU result, 1 = LSU load data
    assign write_data = memtoreg ? load_data : alu_result;

endmodule
