module comparator(
        input [31:0] A,
        input [31:0] B,
        output reg eq,
        output reg lt
    );
    always@(*) begin
        eq = (A == B);
        lt = ($signed(A) < $signed(B));
    end
endmodule
