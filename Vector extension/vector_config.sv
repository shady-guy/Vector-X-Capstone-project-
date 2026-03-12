module vector_config
import vector_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic cfg_write,
    input  logic [31:0] cfg_data,
    input  logic cfg_sel_vl,
    input  logic cfg_sel_sew,
    output logic [31:0] vl,
    output logic [31:0] sew,
    output logic [31:0] epv,
    output logic [LANES-1:0] lane_active
);

always_ff @(posedge clk or posedge rst) begin     //register configuration
    if (rst) begin
        vl  <= VLEN / SEW;
        sew <= SEW;
    end
    else if (cfg_write) begin

        if (cfg_sel_vl)
            vl <= cfg_data;

        if (cfg_sel_sew)
            sew <= cfg_data;

    end
end

assign epv = VLEN / sew;         // elements per vector

integer i;

always_comb begin               //lane control

    for(i=0;i<LANES;i++) begin

        if(i < vl)
            lane_active[i] = 1;

        else
            lane_active[i] = 0;

    end

end

endmodule
