// 2:1 Mux
module mux2 #(parameter WIDTH = 32)(
    input  logic [WIDTH-1:0] d0, d1,
    input  logic sel,
    output logic [WIDTH-1:0] y
);
    assign y = sel ? d1 : d0;
endmodule

// 3:1 Mux
module mux3 #(parameter WIDTH = 32)(
    input  logic [WIDTH-1:0] d0, d1, d2,
    input  logic [1:0] sel,
    output logic [WIDTH-1:0] y
);
    always_comb begin
        case(sel)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = d0;
        endcase
    end
endmodule

// 4:1 Mux
module mux4 #(parameter WIDTH = 32)(
    input  logic [WIDTH-1:0] d0, d1, d2, d3,
    input  logic [1:0] sel,
    output logic [WIDTH-1:0] y
);
    always_comb begin
        case(sel)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            2'b11: y = d3;
            default: y = d0;
        endcase
    end
endmodule
