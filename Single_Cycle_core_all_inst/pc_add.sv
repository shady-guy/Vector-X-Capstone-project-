module pc_adder(
    input logic [31:0]PC,
    input logic [31:0]b,
    output logic [31:0]PC_nxt
);

    always_comb begin 
        PC_nxt = PC + b;
    end

endmodule