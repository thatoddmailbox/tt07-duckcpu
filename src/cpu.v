`default_nettype none

`include "alu_defs.vh"

`define STATE_INSN_FETCH 3'b000
`define STATE_DECODE 3'b001
`define STATE_DATA_L_FETCH 3'b010
`define STATE_DATA_H_FETCH 3'b011
`define STATE_EXECUTE 3'b100
`define STATE_WRITE 3'b101

`define OP_NOP 3'b000
`define OP_LD 3'b001
`define OP_ALU 3'b010
`define OP_JP 3'b011

`define SUBOP_LD_BUS 2'b00
`define SUBOP_LD_REGZ 2'b01

module cpu(
	input wire clk,
	input wire rst_n,

	input wire active,

	output reg [15:0] bus_address_out,
	output reg [7:0] bus_data_out,
	input wire [7:0] bus_data_in,
	output wire bus_read,
	output wire bus_write,
	input wire bus_wait
);

	reg [2:0] state;

	reg [7:0] register_A;
	reg [7:0] register_B;
	reg [7:0] register_C;
	// reg [7:0] register_D;
	// reg [7:0] register_E;
	reg [7:0] register_H;
	reg [7:0] register_L;

	reg [15:0] register_PC;
	reg [15:0] register_SP;

	//
	// instruction decoding
	//

	reg [7:0] current_insn;

`ifdef SIM
	// provides current_insn_name
	`include "instruction_dbg.vh"
`endif

	wire [1:0] insn_x;
	wire [2:0] insn_y;
	wire [2:0] insn_z;

	cpu_decoder decoder(
		.insn(current_insn),
		.insn_x(insn_x),
		.insn_y(insn_y),
		.insn_z(insn_z)
	);

	wire [7:0] insn_y_register_value;
	wire [7:0] insn_z_register_value;

	// TODO: many registers missing
	// TODO: [HL] is not implemented
	assign insn_y_register_value = (insn_y == 3'd0) ? register_B :
	                                (insn_y == 3'd1) ? register_C :
	                                (insn_y == 3'd2) ? 8'h00 : //register_D :
	                                (insn_y == 3'd3) ? 8'h00 : //register_E :
	                                (insn_y == 3'd4) ? register_H :
	                                (insn_y == 3'd5) ? register_L :
	                                (insn_y == 3'd6) ? 8'hAA :
	                                (insn_y == 3'd7) ? register_A :
	                                8'h00;
	assign insn_z_register_value = (insn_z == 3'd0) ? register_B :
	                                (insn_z == 3'd1) ? register_C :
	                                (insn_z == 3'd2) ? 8'h00 : //register_D :
	                                (insn_z == 3'd3) ? 8'h00 : //register_E :
	                                (insn_z == 3'd4) ? register_H :
	                                (insn_z == 3'd5) ? register_L :
	                                (insn_z == 3'd6) ? 8'hAA :
	                                (insn_z == 3'd7) ? register_A :
	                                8'h00;

	// 0 = NZ
	// 1 = Z
	// 2 = NC
	// 3 = C
	wire insn_cc_true;
	assign insn_cc_true = (insn_y == 3'd0) ? !alu_flag_zero :
							(insn_y == 3'd1) ? alu_flag_zero :
							(insn_y == 3'd2) ? !alu_flag_carry :
							(insn_y == 3'd3) ? alu_flag_carry : 0;

	//
	// data pipeline
	//

	reg want_bus_read;
	reg want_bus_write;

	assign bus_read = want_bus_read;
	assign bus_write = want_bus_write;

	reg [7:0] lower_byte;

	// Table "r"
	// Index	0	1	2	3	4	5	6	7
	// Value	B	C	D	E	H	L	(HL)	A
	reg [2:0] target_register;

	reg [2:0] op;
	reg [1:0] subop;

	wire [7:0] ld_input = (subop == `SUBOP_LD_BUS) ? bus_data_in :
	                      (subop == `SUBOP_LD_REGZ) ? insn_z_register_value :
	                      8'h00;

	//
	// alu
	//

	reg [7:0] alu_operand_a;
	reg [7:0] alu_operand_b;
	reg [2:0] alu_operator;
	wire [7:0] alu_result;
	wire alu_flag_zero;
	wire alu_flag_carry;

	alu alu_inst(
		.operand_a(alu_operand_a),
		.operand_b(alu_operand_b),
		.carry_in(1'b0),

		.operator(alu_operator),

		.result(alu_result),

		.flag_zero(alu_flag_zero),
		.flag_carry(alu_flag_carry)
	);

	//
	// main state machine
	//

	always @(posedge clk) begin
		if (!rst_n) begin
			state <= `STATE_INSN_FETCH;
			register_A <= 8'h00;
			register_B <= 8'h00;
			register_C <= 8'h00;
			// register_D <= 8'h00;
			// register_E <= 8'h00;
			register_H <= 8'h00;
			register_L <= 8'h00;
			register_PC <= 16'h0000;
			register_SP <= 16'h0000;

			current_insn <= 8'h00;

			bus_address_out <= 16'h0000;
			bus_data_out <= 8'h00;
			want_bus_read <= 0;
			want_bus_write <= 0;

			lower_byte <= 8'h00;

			target_register <= 3'd0;
			op <= 3'd0;
			subop <= 2'd0;

			alu_operand_a <= 8'h00;
			alu_operand_b <= 8'h00;
			alu_operator <= `ALU_OP_NOP;
		end else if (active) begin
			if (state == `STATE_INSN_FETCH) begin
				if (!want_bus_read) begin
					// fetch the next instruction
					bus_address_out <= register_PC;
					want_bus_read <= 1;
					register_PC <= register_PC + 1;
				end else if (bus_wait) begin
					// wait for the bus to be ready
				end else begin
					// we have the instruction
					current_insn <= bus_data_in;
					want_bus_read <= 0;
					state <= `STATE_DECODE;
				end
			end else if (state == `STATE_DECODE) begin
				// instruction gets decoded by cpu_decoder module
				// based on http://www.z80.info/decoding.htm

`ifdef SIM
				$display("decoding instruction: %b", current_insn);
				$display("decoded instruction: %b %b %b", insn_x, insn_y, insn_z);

				$display("instruction name: %s", current_insn_name);
`endif

				if (insn_x == 2'd0) begin
					if (insn_z == 3'd0) begin
						// NOP
						op <= `OP_NOP;
						state <= `STATE_EXECUTE;
					end else if (insn_z == 3'd4) begin
						// INC r[y]

						alu_operand_a <= insn_y_register_value;
						alu_operand_b <= 8'h01;
						alu_operator <= `ALU_OP_ADD;

						op <= `OP_ALU;
						state <= `STATE_EXECUTE;
						target_register <= insn_y;
					end else if (insn_z == 3'd5) begin
						// DEC r[y]

						alu_operand_a <= insn_y_register_value;
						alu_operand_b <= 8'h01;
						alu_operator <= `ALU_OP_SUB;

						op <= `OP_ALU;
						state <= `STATE_EXECUTE;
						target_register <= insn_y;
					end else if (insn_z == 3'd6) begin
						// LD r[y], n

						op <= `OP_LD;
						subop <= `SUBOP_LD_BUS;
						state <= `STATE_DATA_L_FETCH;

						target_register <= insn_y;
					end else begin
						state <= `STATE_INSN_FETCH;
					end
				end else if (insn_x == 2'd1) begin
					// LD r[y], r[z]

					op <= `OP_LD;
					subop <= `SUBOP_LD_REGZ;
					state <= `STATE_EXECUTE;
					target_register <= insn_y;
				end else if (insn_x == 2'd3) begin
					if (insn_z == 3'd1) begin
						// LD SP, HL
						register_SP <= {register_H, register_L};
						state <= `STATE_INSN_FETCH;
					end else if (insn_z == 3'd2) begin
						// JP cc[y], nn
						if (insn_cc_true) begin
							op <= `OP_JP;
							state <= `STATE_DATA_L_FETCH;
						end else begin
							state <= `STATE_INSN_FETCH;
							// TODO: would be good if this could reuse the JP adders
							register_PC <= register_PC + 2;
						end
					end else if (insn_z == 3'd3) begin
						if (insn_y == 3'd0) begin
							// JP nn
							op <= `OP_JP;
							state <= `STATE_DATA_L_FETCH;
						end else begin
							state <= `STATE_INSN_FETCH;
						end
					end else begin
						state <= `STATE_INSN_FETCH;
					end
				end else begin
					state <= `STATE_INSN_FETCH;
				end
			end else if (state == `STATE_DATA_L_FETCH) begin
				if (!want_bus_read) begin
					// fetch the next byte
					bus_address_out <= register_PC;
					want_bus_read <= 1;
					register_PC <= register_PC + 1;
				end else if (bus_wait) begin
					// wait for the bus to be ready
				end else begin
					// we have the data
					want_bus_read <= 0;

					if (op == `OP_JP) begin
						// need the upper byte, too
						state <= `STATE_DATA_H_FETCH;
						lower_byte <= bus_data_in;
					end else begin
						// move to execute stage
						state <= `STATE_EXECUTE;
					end
				end
			end else if (state == `STATE_DATA_H_FETCH) begin
				if (!want_bus_read) begin
					// fetch the next byte
					bus_address_out <= register_PC;
					want_bus_read <= 1;
					register_PC <= register_PC + 1;
				end else if (bus_wait) begin
					// wait for the bus to be ready
				end else begin
					// we have the data
					want_bus_read <= 0;
					state <= `STATE_EXECUTE;
				end
			end else if (state == `STATE_EXECUTE) begin
				// instruction gets executed

				if (op == `OP_NOP) begin
					// do nothing
					state <= `STATE_INSN_FETCH;
				end else if (op == `OP_LD) begin
					// load the data into the target register

					// TODO: probably other stuff could happen here?
					case (target_register)
						3'd0: register_B <= ld_input;
						3'd1: register_C <= ld_input;
						3'd2: register_C <= ld_input; // register_D <= ld_input;
						3'd3: register_C <= ld_input; // register_E <= ld_input;
						3'd4: register_H <= ld_input;
						3'd5: register_L <= ld_input;
						3'd6: begin
							// writing to [HL]
							bus_address_out <= {register_H, register_L};
							bus_data_out <= ld_input;
							want_bus_write <= 1;
						end
						3'd7: register_A <= ld_input;
					endcase

					if (target_register == 3'd6) begin
						state <= `STATE_WRITE;
					end else begin
						state <= `STATE_INSN_FETCH;
					end
				end else if (op == `OP_ALU) begin
					// do the alu operation

					// TODO: probably other stuff could happen here?
					case (target_register)
						3'd0: register_B <= alu_result;
						3'd1: register_C <= alu_result;
						3'd2: register_C <= alu_result; // register_D <= alu_result;
						3'd3: register_C <= alu_result; // register_E <= alu_result;
						3'd4: register_H <= alu_result;
						3'd5: register_L <= alu_result;
						3'd6: begin
							// writing to [HL]
							bus_address_out <= {register_H, register_L};
							bus_data_out <= alu_result;
							want_bus_write <= 1;
						end
						3'd7: register_A <= alu_result;
					endcase

					if (target_register == 3'd6) begin
						state <= `STATE_WRITE;
					end else begin
						state <= `STATE_INSN_FETCH;
					end
				end else if (op == `OP_JP) begin
					// jump to the address
					register_PC <= {bus_data_in, lower_byte};
					state <= `STATE_INSN_FETCH;
				end
			end else if (state == `STATE_WRITE) begin
				// write back to memory
				if (bus_wait) begin
					// wait for the bus to be ready
				end else begin
					// we have written the data
					want_bus_write <= 0;
					state <= `STATE_INSN_FETCH;
				end
			end
		end
	end

endmodule
