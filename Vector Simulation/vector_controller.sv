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

    logic [6:0] opcode = instruction[6:0];
    logic [2:0] funct3 = instruction[14:12];
    logic [5:0] funct6 = instruction[31:26];
    //logic       vm     = instruction[25];      // mask enable (RVV)

    // Busy state
    //logic vec_busy;
    //assign vec_busy = (instruction[24:20] == 5'b11111) || (instruction[24:20] == 5'b11110);

    // Busy state logic
   /* if (vec_busy) begin
        regwrite = 1'b0;
        lsu_en   = 1'b0;
        memtoreg = 1'b0;
        alu_op   = VADD; // don't care
        lsu_op   = VLOAD;
    end else begin */

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

        // OP-V instructions
        if (opcode == 7'b1010111) begin // OP-V
            case (funct3)
                3'b000: begin // OPIVV
                    case (funct6)
                        6'b000000: alu_op = VADD;
                        6'b000010: alu_op = VSUB;
                        6'b001001: alu_op = VAND;
                        6'b001010: alu_op = VOR;
                        6'b001011: alu_op = VXOR;
                        6'b000111: alu_op = VMIN;
                        6'b000101: alu_op = VMAX;
                        default:   alu_op = VADD;
                    endcase
                    regwrite = 1'b1;
                end
            endcase
        end
    end
    //end

endmodule
