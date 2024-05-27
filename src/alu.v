`default_nettype none

`include "alu_defs.vh"

module alu(
	input wire clk,
	input wire rst_n,

	input wire [7:0] operand_a,
	input wire [7:0] operand_b,

	input wire [2:0] operator,

	output reg [7:0] result
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
		end
	end

endmodule