`default_nettype none

module cpu_decoder(
	input wire [7:0] insn,

	output wire [1:0] insn_x,
	output wire [2:0] insn_y,
	output wire [2:0] insn_z
);

	assign insn_x = insn[7:6];
	assign insn_y = insn[5:3];
	assign insn_z = insn[2:0];

endmodule
