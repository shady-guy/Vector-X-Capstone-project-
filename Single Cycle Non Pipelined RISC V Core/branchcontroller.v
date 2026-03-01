module branchcontroller (
	input  [2:0] funct3,
	output [1:0] branchcontrol
);
	assign branchcontrol = {funct3[2], funct3[0]};
endmodule
