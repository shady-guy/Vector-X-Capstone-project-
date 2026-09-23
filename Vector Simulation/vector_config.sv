module vector_config
import vector_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic cfg_write,
    input  logic [31:0] cfg_data,
    input  logic cfg_sel_vl,
    input  logic cfg_sel_sew,
    input  logic cfg_sel_vma,
    input  logic cfg_sel_vta,
    input  logic cfg_sel_vlmul,
    output logic [31:0] vl,
    output logic [31:0] sew,
    output logic [31:0] epv,
    output logic [LANES-1:0] lane_active,
    //aditional ports
    output logic vma,
    output logic vta,
    output logic [2:0] vsew
);

//internal registers for configuration
vtype_t vtype_reg;
logic [31:0] vl_reg;

// Configuration register write logic
// adjustable to allow configurability for different tasks
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        vl_reg <= VLEN / SEW;
        vtype_reg.vsew <=3'd2;      //default encoding =2 => 32-bit elements
        vtype_reg.vta <=1'b1;       //default is tail agnostic enabled
        vtype_reg.vlmul <= 2'd0;    //default LMUL=1
        vtype_reg.vma <=1'b1;       //default is mask agnostic enabled
        sew <= SEW;
    end
    //updating only when signal to config csr is high --> flexible
    else if (cfg_write) begin       
        if (cfg_sel_vl) begin
            vl_reg <= cfg_data;                //changeable vl
        end
        if (cfg_sel_sew) begin
            vtype_reg.vsew <= cfg_data[2:0];    //changeable sew encoding
            sew <=8 << cfg_data[2:0];           //ecoding to actual SEW value
        end
        if (cfg_sel_vma) begin
            vtype_reg.vma <= cfg_data[0];       
        end
        if (cfg_sel_vta) begin
            vtype_reg.vta <= cfg_data[0];
        end
        if (cfg_sel_vlmul) begin
            vtype_reg.vlmul <= cfg_data[1:0];
        end
    end
end

// Synchronous update of visible `vl` to avoid combinational race in older toolchains
// Clamp `vl` to physical `VLMAX` whenever configuration registers change.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        vl <= VLEN / SEW;
    end else if (cfg_write) begin
        int VLMAX;
        VLMAX = vlmax(VLEN, vtype_reg);
        if (vl_reg > VLMAX)
            vl <= VLMAX;
        else
            vl <= vl_reg;
    end
end


/*always_ff @(posedge clk or posedge rst) begin     //register configuration
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
end */

assign epv = VLEN / sew_frm_vtype(vtype_reg);         // elements per vector
assign vma  = vtype_reg.vma;
assign vta  = vtype_reg.vta;
assign vsew = vtype_reg.vsew;

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