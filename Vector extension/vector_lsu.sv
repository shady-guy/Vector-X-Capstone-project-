/* This file contains the RTL for vector load/store unit 
Add handshaking later (for pipeline implementation)
*/

module vector_lsu 
import vector_pkg::*;
( 
    input logic clk,
    input logic rst,

    //control signals
    input vector_mem_mode_t mode, //and other stuff from pkg if needed
    input vec_opcode_t lsuop, //to determine load vs store, and other operations if needed

    //inputs config
    input logic [15:0] vl, //count of active vector elements 
    input logic [31:0] base_addr,
    input logic [31:0] stride, //stride mode
    input logic [VLEN-1:0] index_vector, //index mode
    input logic [VLEN-1:0] store_data,

    output logic [VLEN-1:0] load_data,

    //memory interfacing
    output logic [31:0] mem_addr,
    output logic mem_req,        //request to memory
    output logic mem_read,
    output logic mem_write,
    output logic [ELEN-1:0] mem_wdata,
    input logic mem_valid,        //memory valid data signal
    input logic [ELEN-1:0] mem_rdata,

    //finish
    output logic done
    );

// Internal signals
logic [15:0] elem_idx; //index of current element
logic [31:0] addr; //calculated mem_addr for current element
logic load;
logic store;
assign load = (op == VLD);
assign store = (op == VST);

localparam SHIFT  = $clog2(ELEN/8); //number of bits to shift for element size
//LSU operation modes
always_comb begin : LSU_Mode
    logic [ELEN-1:0] curr_index;
    logic[31:0] offset;
    curr_index = index_vector[elem_idx*ELEN +: ELEN];
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
assign mem_req = (state == EXEC);  //request memory when executing
assign mem_read = load;
assign mem_write = store;

assign mem_wdata = store_data[elem_idx*ELEN +: ELEN]; //extracting 1 element width starting from elem_idx*ELEN

always_ff @(posedge clk ) begin : Loads
    if (load && mem_valid) begin
        load_data[elem_idx*ELEN+:ELEN] <= mem_rdata;
    end
end

logic start;
assign start = load || store; //start LSU when either load or store is asserted

//LSU FSM
typedef enum logic [1:0]{
    IDLE,
    EXEC,
    DONE
} state_t;
state_t state, nstate;
always_ff @(posedge clk or posedge rst) begin : FSM
    if (rst) begin
        state <= IDLE;
    end
    else begin
        state <= nstate;
    end
end

always_comb begin : Next_State
    case (state)
        IDLE: begin
            if (start) begin
                nstate = EXEC;
            end
            else nstate = IDLE;
        end
        EXEC: begin
            if (mem_valid && elem_idx == vl-1) nstate = DONE;  //wait for valid before checking done
            else nstate = EXEC;
        end
        DONE: begin
            nstate = IDLE;
        end
        default: nstate = IDLE;
    endcase
end
always_ff @( posedge clk or posedge rst ) begin : LSU_OP
    if (rst) begin
        elem_idx <=0;
        done <=0;
    end
    else if (state== IDLE && start) begin
        elem_idx <=0;
        done<=0;
    end
    else if (state == EXEC && mem_valid) begin  //wait for valid before incrementing
          elem_idx <= elem_idx +1;
    end
    else if (state == DONE) begin
        done <=1;
    end
end

endmodule
