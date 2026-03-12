module imem #(parameter WORDS = 64,
              parameter mem_init = "")
(
    input  logic [31:0] addr,
    output logic [31:0] rd
);
    logic [31:0] mem [WORDS-1:0];

    initial begin
        $readmemh(mem_init, mem);
    end

    // word addressed, read only
    assign rd = mem[addr[31:2]];

endmodule
