module regfile (
    input logic clk,
    input logic rst,
    //for read 
    input logic [4:0]addr1,addr2,               
    output logic [31:0]rd1,rd2,
    //for write
    input logic [4:0]addr3,
    input logic [31:0]wr_data,
    input logic regwrite

);

logic [31:0] rf[31:0];

always_ff @(posedge clk) begin : Write
    if(rst) begin
        for(int i=0; i<32; i++) begin
            rf[i] <= 32'd0;
        end
    end
    else if(regwrite)   rf[addr3] <= wr_data; 
end

always_comb begin : read
    rd1 = (addr1 == 5'd0)? 32'b0:rf[addr1];
    rd2 = (addr2 == 5'd0)? 32'b0:rf[addr2];
end
endmodule