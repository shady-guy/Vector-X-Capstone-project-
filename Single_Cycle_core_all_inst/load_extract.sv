module load_extract (
    input logic [31:0] raw_data, //rd from mem.sv
    input logic [2:0]  funct3,
    input logic [1:0]  byte_offset, //addr[1:0] from mem.sv
    output logic [31:0] load_data
);

    always_comb begin
        case(funct3)
            3'b000: begin // lb
                case(byte_offset)
                    2'b00: load_data = {{24{raw_data[7]}},  raw_data[7:0]};
                    2'b01: load_data = {{24{raw_data[15]}}, raw_data[15:8]};
                    2'b10: load_data = {{24{raw_data[23]}}, raw_data[23:16]};
                    2'b11: load_data = {{24{raw_data[31]}}, raw_data[31:24]};
                endcase
            end
            3'b001: begin // lh
                case(byte_offset[1])
                    1'b0: load_data = {{16{raw_data[15]}}, raw_data[15:0]};
                    1'b1: load_data = {{16{raw_data[31]}}, raw_data[31:16]};
                endcase
            end
            3'b010: load_data = raw_data; // lw
            3'b100: begin // lbu
                case(byte_offset)
                    2'b00: load_data = {24'b0, raw_data[7:0]};
                    2'b01: load_data = {24'b0, raw_data[15:8]};
                    2'b10: load_data = {24'b0, raw_data[23:16]};
                    2'b11: load_data = {24'b0, raw_data[31:24]};
                endcase
            end
            3'b101: begin // lhu
                case(byte_offset[1])
                    1'b0: load_data = {16'b0, raw_data[15:0]};
                    1'b1: load_data = {16'b0, raw_data[31:16]};
                endcase
            end
            default: load_data = raw_data;
        endcase
    end

endmodule