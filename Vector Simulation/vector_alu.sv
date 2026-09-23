import vector_pkg::*;

module VALU (
    input  vector_opcode_t            op,
    input  logic [VLEN-1:0]           vs1,
    input  logic [VLEN-1:0]           vs2,
    input  logic [$clog2(LANES+1)-1:0] vl,
    input  logic [VLEN-1:0]           vd_old,
    input  logic [VLEN-1:0]           mask,
    input  logic                      vma,
    input  logic                      vta,
    output logic [VLEN-1:0]           vd
);

generate
    for (genvar i = 0; i < LANES; i++) begin : alu_lanes
        wire [SEW-1:0] vs1_lane    = vs1[(i+1)*SEW-1 : i*SEW];
        wire [SEW-1:0] vs2_lane    = vs2[(i+1)*SEW-1 : i*SEW];
        wire [SEW-1:0] vd_old_lane = vd_old[(i+1)*SEW-1 : i*SEW];
        logic [SEW-1:0] vd_lane;

        always_comb begin
            if (i < vl) begin
                if (mask[i]) begin
                    case (op)
                        VADD:  vd_lane = vs1_lane + vs2_lane;
                        VSUB:  vd_lane = vs1_lane - vs2_lane;
                        VAND:  vd_lane = vs1_lane & vs2_lane;
                        VOR:   vd_lane = vs1_lane | vs2_lane;
                        VXOR:  vd_lane = vs1_lane ^ vs2_lane;
                        VSLL:  vd_lane = vs1_lane << vs2_lane[$clog2(SEW)-1:0];
                        VSRL:  vd_lane = vs1_lane >> vs2_lane[$clog2(SEW)-1:0];
                        VSRA:  vd_lane = $signed(vs1_lane) >>> vs2_lane[$clog2(SEW)-1:0];
                        VMIN:  vd_lane = ($signed(vs1_lane) < $signed(vs2_lane)) ? vs1_lane : vs2_lane;
                        VMAX:  vd_lane = ($signed(vs1_lane) > $signed(vs2_lane)) ? vs1_lane : vs2_lane;
                        VMINU: vd_lane = (vs1_lane < vs2_lane) ? vs1_lane : vs2_lane;
                        VMAXU: vd_lane = (vs1_lane > vs2_lane) ? vs1_lane : vs2_lane;
                        default: vd_lane = '0;
                    endcase
                end else begin
                    vd_lane = vma ? '0 : vd_old_lane;
                end
            end else begin
                vd_lane = vta ? '0 : vd_old_lane;
            end
        end

        assign vd[(i+1)*SEW-1 : i*SEW] = vd_lane;
    end
endgenerate

endmodule