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

module cpu(
	input wire clk,
	input wire rst_n,

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

	reg [15:0] register_PC;

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
	// TODO: many registers missing
	// TODO: [HL] is not implemented
	assign insn_y_register_value = (insn_y == 3'd0) ? register_B :
	                                (insn_y == 3'd1) ? 8'hBB : //register_C :
	                                (insn_y == 3'd2) ? 8'hBB : //register_D :
	                                (insn_y == 3'd3) ? 8'hBB : //register_E :
	                                (insn_y == 3'd4) ? 8'hBB : //register_H :
	                                (insn_y == 3'd5) ? 8'hBB : //register_L :
	                                (insn_y == 3'd6) ? 8'hAA :
	                                (insn_y == 3'd7) ? register_A :
	                                8'h00;

	// 0 = NZ
	// 1 = Z
	// 2 = NC
	// 3 = C
	wire insn_cc_true;
	assign insn_cc_true = (insn_y == 2'd0) ? !alu_flag_zero :
							(insn_y == 2'd1) ? alu_flag_zero :
							(insn_y == 2'd2) ? !alu_flag_carry :
							(insn_y == 2'd3) ? alu_flag_carry : 0;

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
		.clk(clk),
		.rst_n(rst_n),

		.operand_a(alu_operand_a),
		.operand_b(alu_operand_b),

		.operator(alu_operator),

		.result(alu_result),

		.flag_zero(alu_flag_zero),
		.flag_carry(alu_flag_carry)
	);

	//
	// main state machine
	//

	always @(posedge clk) begin
		$display("\nclk start");
		if (!rst_n) begin
			$display("reset");
			state <= `STATE_INSN_FETCH;
			register_A <= 8'h00;
			register_B <= 8'h00;
			register_PC <= 16'h0000;

			bus_address_out <= 16'h0000;
			bus_data_out <= 8'h00;
			want_bus_read <= 0;
			want_bus_write <= 0;

			lower_byte <= 8'h00;

			target_register <= 3'd0;
			op <= 3'd0;

			alu_operand_a <= 8'h00;
			alu_operand_b <= 8'h00;
			alu_operator <= `ALU_OP_NOP;
		end else begin
			if (state == `STATE_INSN_FETCH) begin
				$display("insn fetch");
				$display("want_bus_read: %b", want_bus_read);

				if (!want_bus_read) begin
					$display("fetching next instruction");
					$display("PC: %h", register_PC);
					// fetch the next instruction
					bus_address_out <= register_PC;
					want_bus_read <= 1;
					register_PC <= register_PC + 1;
				end else if (bus_wait) begin
					// wait for the bus to be ready
					$display("waiting for bus");
				end else begin
					// we have the instruction
					$display("have insn");
					current_insn <= bus_data_in;
					want_bus_read <= 0;
					state <= `STATE_DECODE;

					$display("got instruction: %b", bus_data_in);
				end
			end else if (state == `STATE_DECODE) begin
				// instruction gets decoded by cpu_decoder module
				// based on http://www.z80.info/decoding.htm

				$display("decoding instruction: %b", current_insn);
				$display("decoded instruction: %b %b %b", insn_x, insn_y, insn_z);

`ifdef SIM
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

						// TODO: flags???

						op <= `OP_ALU;
						state <= `STATE_EXECUTE;
						target_register <= insn_y;
					end else if (insn_z == 3'd5) begin
						// DEC r[y]

						alu_operand_a <= insn_y_register_value;
						alu_operand_b <= 8'h01;
						alu_operator <= `ALU_OP_SUB;

						// TODO: flags???

						op <= `OP_ALU;
						state <= `STATE_EXECUTE;
						target_register <= insn_y;
					end else if (insn_z == 3'd6) begin
						// LD r[y], n

						$display("it's a load");

						op <= `OP_LD;
						state <= `STATE_DATA_L_FETCH;

						target_register <= insn_y;
					end else begin
						state <= `STATE_INSN_FETCH;
					end
				end else if (insn_x == 2'd3) begin
					if (insn_z == 3'd2) begin
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
				$display("STATE_DATA_L_FETCH");
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
				$display("STATE_DATA_H_FETCH");
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
				end else if (op == `OP_LD) begin
					// load the data into the target register

					// TODO: probably other stuff could happen here?
					case (target_register)
						3'd0: register_B <= bus_data_in;
						// 3'd1: register_C <= bus_data_in;
						// 3'd2: register_D <= bus_data_in;
						// 3'd3: register_E <= bus_data_in;
						// 3'd4: register_H <= bus_data_in;
						// 3'd5: register_L <= bus_data_in;
						// TODO: what about [HL]?
						3'd7: register_A <= bus_data_in;
					endcase

					state <= `STATE_INSN_FETCH;
				end else if (op == `OP_ALU) begin
					// do the alu operation

					// TODO: probably other stuff could happen here?
					case (target_register)
						3'd0: register_B <= alu_result;
						// 3'd1: register_C <= alu_result;
						// 3'd2: register_D <= alu_result;
						// 3'd3: register_E <= alu_result;
						// 3'd4: register_H <= alu_result;
						// 3'd5: register_L <= alu_result;
						// TODO: what about [HL]?
						3'd7: register_A <= alu_result;
					endcase

					state <= `STATE_INSN_FETCH;
				end else if (op == `OP_JP) begin
					// jump to the address
					register_PC <= {bus_data_in, lower_byte};
					state <= `STATE_INSN_FETCH;
				end
			end else if (state == `STATE_WRITE) begin
				// write back to memory
			end
		end
	end

endmodule
