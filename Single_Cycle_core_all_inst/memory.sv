module memory #(parameter WORDS = 64,
                parameter mem_init = ""
    )(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [31:0] addr,
    input logic [2:0] funct3,
    input logic [31:0] wr_data,
    output logic [31:0] rd,
    output logic misalign
);

    //memory array
    logic [31:0] mem[WORDS-1:0];
    logic [3:0] byte_en;
    logic [31:0] shifted_wr_data;

    initial begin
        $readmemh(mem_init, mem);
    end

    always_comb begin
        case(funct3)
            3'b001, 3'b101: misalign = addr[0]; //sh,lh and lhu misalignment
            3'b010: misalign = |addr[1:0]; //sw and lw misalignment
            default: misalign = 1'b0;
        endcase
    end

    always@(posedge clk) begin: write
        if(rst) begin
            for(int i=0; i<32; i++) begin
                mem[i] <=32'd0;
            end
        end
        else if(wr_en && !misalign) begin
            case(funct3)
                3'b000: begin // sb
                    case(addr[1:0])
                        2'b00: mem[addr[31:2]][7:0]   <= wr_data[7:0];
                        2'b01: mem[addr[31:2]][15:8]  <= wr_data[7:0];
                        2'b10: mem[addr[31:2]][23:16] <= wr_data[7:0];
                        2'b11: mem[addr[31:2]][31:24] <= wr_data[7:0];
                    endcase
                end
                3'b001: begin // sh
                    case(addr[1])
                        1'b0: mem[addr[31:2]][15:0]  <= wr_data[15:0];
                        1'b1: mem[addr[31:2]][31:16] <= wr_data[15:0];
                    endcase
                end
                3'b010: mem[addr[31:2]] <= wr_data; // sw
            endcase
        end
    end

    always_comb begin : read
        rd = mem[addr[31:2]];
    end

endmodule