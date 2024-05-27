`default_nettype none

`include "alu_defs.vh"

module alu(
	input wire clk,
	input wire rst_n,

	input wire [7:0] operand_a,
	input wire [7:0] operand_b,

	input wire [2:0] operator,

	output reg [7:0] result,

	output reg flag_zero,
	output reg flag_carry
);

	always @(posedge clk) begin
		if (!rst_n) begin
			result <= 8'h00;
		end else begin
			case (operator)
				`ALU_OP_ADD: result <= operand_a + operand_b;
				`ALU_OP_SUB: result <= operand_a - operand_b;
				`ALU_OP_AND: result <= operand_a & operand_b;
				`ALU_OP_OR: result <= operand_a | operand_b;
				`ALU_OP_XOR: result <= operand_a ^ operand_b;
				default: result <= 8'h71;
			endcase

			flag_zero <= (result == 8'h00);
			flag_carry <= 0; // TODO: implement carry flag
		end
	end

endmodule