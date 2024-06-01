`default_nettype none

`include "alu_defs.vh"

module alu(
	input wire [7:0] operand_a,
	input wire [7:0] operand_b,
	input wire carry_in,

	input wire [2:0] operator,

	output wire [7:0] result,

	output wire flag_zero,
	output wire flag_carry
);

	wire [8:0] internal_result = (operator == `ALU_OP_ADD) ? operand_a + operand_b + carry_in :
									(operator == `ALU_OP_SUB) ? operand_a - operand_b - carry_in :
									(operator == `ALU_OP_AND) ? operand_a & operand_b :
									(operator == `ALU_OP_OR) ? operand_a | operand_b :
									(operator == `ALU_OP_XOR) ? operand_a ^ operand_b :
									8'h71;

	assign result = internal_result[7:0];
	assign flag_zero = (result == 8'h00);
	assign flag_carry = internal_result[8];

endmodule
