/* This file contains the RTL for vector load/store unit 
Add handshaking later (for pipeline implementation)
*/

module vector_lsu
import vector_pkg::*;
( 
    input logic clk,
    input logic rst,

    //control signals
    input vector_mem_mode_t mode,
    input vector_opcode_t op, //to determine load vs store

    //inputs config
    input logic [15:0] vl, //count of active vector elements 
    input logic [31:0] base_addr,
    input logic [31:0] stride, //stride mode
    input logic [VLEN-1:0] index_vector, //index mode
    input logic [VLEN-1:0] store_data,
    input logic [2:0] vsew,
    output logic [VLEN-1:0] load_data,

    //memory interfacing
    output logic [31:0] mem_addr,
    output logic mem_req,        //request to memory
    output logic mem_read,
    output logic mem_write,
    output logic [ELEN-1:0] mem_wdata,
    input logic mem_valid,        //memory valid data signal
    input logic [ELEN-1:0] mem_rdata,
    input logic       lsu_en,
    //finish
    output logic done
    );

// Internal signals
logic [15:0] elem_idx; //index of current element
logic [31:0] addr; //calculated mem_addr for current element
logic load;
logic store;
assign load = (op == VLOAD);
assign store = (op == VSTORE);
logic [31:0] elem_shift;

// LSU FSM state (declared early for older toolchains)
typedef enum logic [1:0] {
    S_IDLE,
    S_EXEC,
    S_DONE
} state_t;
state_t state, nstate;

//localparam SHIFT  = $clog2(ELEN/8); //number of bits to shift for element size
logic [2:0] SHIFT; //suport variable element sizes from config
assign SHIFT = vsew;
assign elem_shift = elem_idx << SHIFT;

logic start;
assign start = lsu_en && (load || store); //start LSU when either load or store is asserted

//LSU operation modes
always_comb begin : LSU_Mode
    logic [63:0] curr_index;
    logic[31:0] offset;
    case (SHIFT)
        3'd0: curr_index = index_vector[elem_shift*8 +: 8];
        3'd1: curr_index = index_vector[elem_shift*8 +: 16];
        3'd2: curr_index = index_vector[elem_shift*8 +: 32];
        3'd3: curr_index = index_vector[elem_shift*8 +: 64];
        default: curr_index = 0;
    endcase
    //curr_index = index_vector[elem_idx*ELEN +: ELEN];
    unique case (mode) //allows mux optimization
        UNIT_STRIDE: begin
            offset = elem_idx << SHIFT; 
        end
        STRIDE: begin
            offset = elem_idx * stride;
        end
        INDEX: begin
            offset = curr_index << SHIFT; 
        end
        default: begin
            offset = '0;
        end
    endcase
    addr = base_addr + offset;
end

//control signal enablers
assign mem_addr = addr;
assign mem_req = (state == S_EXEC) && lsu_en;  //request memory when executing and LSU enabled
assign mem_read = load && mem_req;
assign mem_write = store && mem_req;

//assign mem_wdata = store_data[elem_idx*ELEN +: ELEN]; //extracting 1 element width starting from elem_idx*ELEN
//assign mem_wdata = store_data[elem_shift*8 +: (8 << SHIFT)];

/*always_ff @(posedge clk ) begin : Loads
    if (load && mem_valid) begin
        load_data[elem_shift*8 +: (8 << SHIFT)] <= mem_rdata;
        //load_data[elem_idx*ELEN+:ELEN] <= mem_rdata;
    end
end */
always_comb begin
  case (SHIFT)
    3'd0: mem_wdata = store_data[elem_shift*8 +: 8];
    3'd1: mem_wdata = store_data[elem_shift*8 +: 16];
    3'd2: mem_wdata = store_data[elem_shift*8 +: 32];
    3'd3: mem_wdata = store_data[elem_shift*8 +: 64];
    default: mem_wdata = '0;
  endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        load_data <= '0;
    end else if (state == S_IDLE && start && load) begin
        load_data <= '0;
    end else if (load && mem_valid) begin
        case (SHIFT)
            3'd0: load_data[elem_shift*8 +: 8]  <= mem_rdata;
            3'd1: load_data[elem_shift*8 +: 16] <= mem_rdata;
            3'd2: load_data[elem_shift*8 +: 32] <= mem_rdata;
            3'd3: load_data[elem_shift*8 +: 64] <= mem_rdata;
            default: ;
        endcase
    end
end

//LSU FSM
always_ff @(posedge clk or posedge rst) begin : FSM
    if (rst) begin
        state <= S_IDLE;
    end
    else begin
        state <= nstate;
    end
end

always_comb begin : Next_State
    case (state)
        S_IDLE: begin
            if (start) begin
                nstate = S_EXEC;
            end
            else nstate = S_IDLE;
        end
        S_EXEC: begin
            if (mem_valid && elem_idx == vl-1) nstate = S_DONE;  //wait for valid before checking done
            else nstate = S_EXEC;
        end
        S_DONE: begin
            nstate = S_IDLE;
        end
        default: nstate = S_IDLE;
    endcase
end
always_ff @( posedge clk or posedge rst ) begin : LSU_OP
    if (rst) begin
        elem_idx <=0;
        done <=0;
    end
    else if (state == S_IDLE && start) begin
        elem_idx <=0;
        done<=0;
    end
    else if (state == S_EXEC && mem_valid) begin  //wait for valid before incrementing
          elem_idx <= elem_idx +1;
    end
    else if (state == S_DONE) begin
        done <=1;
    end
end

endmodule
