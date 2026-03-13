// Vector Controller
// Mirrors scalar ctrl_main.sv two-level decode style
//
// Instruction Format (32-bit):
//  [31:28] op    : 4-bit vector opcode  -> vector_opcode_t
//  [27:23] rd    : 5-bit dest register
//  [22:18] rs1   : 5-bit source reg 1
//  [17:13] rs2   : 5-bit source reg 2
//  [12:11] mode  : 2-bit LSU access mode -> vector_mem_mode_t
//  [10:0]  imm   : 11-bit immediate (used as stride for LSU)

module vector_controller
import vector_pkg::*;
(
    input  logic [31:0]          instruction,

    // Register file control
    output logic                 regwrite,

    // ALU control
    output vector_opcode_t       alu_op,

    // LSU control
    output vector_opcode_t       lsu_op,
    output vector_mem_mode_t     mode,
    output logic                 lsu_en,

    // Writeback mux: 0 = ALU result, 1 = load data
    output logic                 memtoreg,

    // Config unit control
    output logic                 cfg_write,
    output logic                 cfg_sel_vl,
    output logic                 cfg_sel_sew
);

    // Decode instruction fields
    logic [3:0]              op_raw;
    vector_opcode_t          op;
    assign op_raw = instruction[31:28];
    assign op     = vector_opcode_t'(op_raw);

    // Main decoder — mirrors always_comb block style from ctrl_main.sv
    always_comb begin : Main_Decoder
        // Safe defaults
        regwrite    = 1'b0;
        alu_op      = VADD;
        lsu_op      = VLOAD;
        lsu_en      = 1'b0;
        memtoreg    = 1'b0;
        mode        = vector_mem_mode_t'(instruction[12:11]);
        cfg_write   = 1'b0;
        cfg_sel_vl  = 1'b0;
        cfg_sel_sew = 1'b0;

        case (op)
            // ---- ALU operations: write ALU result back to reg file ----
            VADD,
            VSUB,
            VAND,
            VOR,
            VXOR,
            VSLL,
            VSRL,
            VSRA,
            VMIN,
            VMAX,
            VMINU,
            VMAXU: begin
                regwrite = 1'b1;
                alu_op   = op;
                memtoreg = 1'b0;   // write ALU result
                lsu_en   = 1'b0;
            end

            // ---- VLOAD: LSU reads memory, writes to reg file ----
            VLOAD: begin
                regwrite = 1'b1;
                lsu_op   = VLOAD;
                lsu_en   = 1'b1;
                memtoreg = 1'b1;   // write load data
            end

            // ---- VSTORE: LSU writes to memory, no reg file write ----
            VSTORE: begin
                regwrite = 1'b0;
                lsu_op   = VSTORE;
                lsu_en   = 1'b1;
                memtoreg = 1'b0;
            end

            default: begin
                regwrite = 1'b0;
                lsu_en   = 1'b0;
            end
        endcase
    end

endmodule
