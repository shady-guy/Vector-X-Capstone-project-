// Vector Top Module
// Contains: PC, PC+4 adder, instruction memory
// Instantiates: vector_controller + vector_datapath
// Exposes: data memory interface (connect to external SRAM/memory)

module vector_top
import vector_pkg::*;
#(
    parameter int IMEM_DEPTH = 256    // number of instructions
)
(
    input  logic clk,
    input  logic rst,

    // Config input — cfg_data can come from scalar core or be hardwired
    input  logic [31:0] cfg_data,

    // Data memory interface (external)
    output logic [31:0]     mem_addr,
    output logic            mem_req,
    output logic            mem_read,
    output logic            mem_write,
    output logic [ELEN-1:0] mem_wdata,
    input  logic            mem_valid,
    input  logic [ELEN-1:0] mem_rdata,

    // Status
    output logic            lsu_done
);

    // ----------------------------------------------------------------
    // PC
    // ----------------------------------------------------------------
    logic [31:0] pc, pc_next;

    always_ff @(posedge clk) begin : PC_Reg
        if (rst) pc <= 32'd0;
        else     pc <= pc_next;
    end

    assign pc_next = pc + 32'd4;   // single cycle: always PC+4

    // ----------------------------------------------------------------
    // Instruction Memory (synchronous read ROM)
    // Load your program into imem via $readmemh in simulation
    // ----------------------------------------------------------------
    logic [31:0] imem [0:IMEM_DEPTH-1];
    logic [31:0] instruction;

    initial begin
        for (int i = 0; i < IMEM_DEPTH; i++)
            imem[i] = 32'd0;
        // Uncomment to load from file in simulation:
        // $readmemh("vector_program.hex", imem);
    end

    assign instruction = imem[pc[31:2]];   // word-addressed

    // ----------------------------------------------------------------
    // Controller
    // ----------------------------------------------------------------
    logic                 regwrite;
    vector_opcode_t       alu_op;
    vector_opcode_t       lsu_op;
    vector_mem_mode_t     mode;
    logic                 lsu_en;
    logic                 memtoreg;
    logic                 cfg_write;
    logic                 cfg_sel_vl;
    logic                 cfg_sel_sew;

    vector_controller ctrl (
        .instruction (instruction),
        .regwrite    (regwrite),
        .alu_op      (alu_op),
        .lsu_op      (lsu_op),
        .mode        (mode),
        .lsu_en      (lsu_en),
        .memtoreg    (memtoreg),
        .cfg_write   (cfg_write),
        .cfg_sel_vl  (cfg_sel_vl),
        .cfg_sel_sew (cfg_sel_sew)
    );

    // ----------------------------------------------------------------
    // Datapath
    // ----------------------------------------------------------------
    vector_datapath dp (
        .clk         (clk),
        .rst         (rst),
        .instruction (instruction),
        .regwrite    (regwrite),
        .alu_op      (alu_op),
        .lsu_op      (lsu_op),
        .mode        (mode),
        .lsu_en      (lsu_en),
        .memtoreg    (memtoreg),
        .cfg_write   (cfg_write),
        .cfg_sel_vl  (cfg_sel_vl),
        .cfg_sel_sew (cfg_sel_sew),
        .cfg_data    (cfg_data),
        .mem_addr    (mem_addr),
        .mem_req     (mem_req),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_wdata   (mem_wdata),
        .mem_valid   (mem_valid),
        .mem_rdata   (mem_rdata),
        .lsu_done    (lsu_done)
    );

endmodule
