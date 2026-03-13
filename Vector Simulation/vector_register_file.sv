// Vector Register File
// 32 registers, each VLEN (256) bits wide
// Sync write, async read — mirrors scalar regfile.sv style
// v0 hardwired to zero

module vector_register_file
import vector_pkg::*;
(
    input  logic clk,
    input  logic rst,

    // Read ports
    input  logic [4:0]      addr1,
    input  logic [4:0]      addr2,
    output logic [VLEN-1:0] rd1,
    output logic [VLEN-1:0] rd2,

    // Write port
    input  logic [4:0]      addr3,
    input  logic [VLEN-1:0] wr_data,
    input  logic            regwrite
);

    logic [VLEN-1:0] vrf [MAX_VREG-1:0];

    // Synchronous write with reset
    always_ff @(posedge clk) begin : Write
        if (rst) begin
            for (int i = 0; i < MAX_VREG; i++)
                vrf[i] <= '0;
        end
        else if (regwrite)
            vrf[addr3] <= wr_data;
    end

    // Asynchronous read, v0 hardwired to zero
    always_comb begin : Read
        rd1 = (addr1 == 5'd0) ? '0 : vrf[addr1];
        rd2 = (addr2 == 5'd0) ? '0 : vrf[addr2];
    end

endmodule
