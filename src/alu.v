`default_nettype none

`include "alu_defs.vh"

module alu(
	input wire [7:0] operand_a,
	input wire [7:0] operand_b,

	input wire [2:0] operator,

	output wire [7:0] result,

	output wire flag_zero,
	output wire flag_carry
);

	assign result = (operator == `ALU_OP_ADD) ? operand_a + operand_b :
					(operator == `ALU_OP_SUB) ? operand_a - operand_b :
					(operator == `ALU_OP_AND) ? operand_a & operand_b :
					(operator == `ALU_OP_OR) ? operand_a | operand_b :
					(operator == `ALU_OP_XOR) ? operand_a ^ operand_b :
					8'h71;
	assign flag_zero = (result == 8'h00);
	assign flag_carry = 0; // TODO: implement carry flag

	// always @(posedge clk) begin
	// 	if (!rst_n) begin
	// 		result <= 8'h00;
	// 	end else begin
	// 		case (operator)
	// 			`ALU_OP_ADD: result <= operand_a + operand_b;
	// 			`ALU_OP_SUB: result <= operand_a - operand_b;
	// 			`ALU_OP_AND: result <= operand_a & operand_b;
	// 			`ALU_OP_OR: result <= operand_a | operand_b;
	// 			`ALU_OP_XOR: result <= operand_a ^ operand_b;
	// 			default: result <= 8'h71;
	// 		endcase

	// 		flag_zero <= (result == 8'h00);
	// 		flag_carry <= 0; // TODO: implement carry flag
	// 	end
	// end

endmodule
