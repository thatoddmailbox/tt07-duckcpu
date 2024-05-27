`default_nettype none

`define STATE_READ_INSN 3'b000
`define STATE_WAIT_FOR_BUS_INSN 3'b001
`define STATE_EXEC 3'b010
`define STATE_WAIT_FOR_BUS_DATA 3'b011

module cpu(
	input wire clk,
	input wire rst_n,

	output reg [15:0] bus_address_out,
	output reg [7:0] bus_data_out,
	input wire [7:0] bus_data_in,
	output reg bus_read,
	output reg bus_write,
	input wire bus_done
);

	reg [2:0] state;

	reg [7:0] register_A;
	reg [7:0] register_B;

	reg [15:0] register_IP;

	//
	// instruction decoding
	//

	reg [7:0] current_insn;

	wire [1:0] insn_x;
	wire [2:0] insn_y;
	wire [2:0] insn_z;

	cpu_decoder decoder(
		.insn(current_insn),
		.insn_x(insn_x),
		.insn_y(insn_y),
		.insn_z(insn_z)
	);

	//
	// data pipeline
	//

	// Table "r"
	// Index	0	1	2	3	4	5	6	7
	// Value	B	C	D	E	H	L	(HL)	A
	reg [2:0] target_register;

	always @(posedge clk) begin
		if (!rst_n) begin
			state <= `STATE_READ_INSN;
			register_A <= 8'h00;
			register_B <= 8'h00;
			register_IP <= 16'h0000;

			bus_address_out <= 16'h0000;
			bus_data_out <= 8'h00;
			bus_read <= 0;
			bus_write <= 0;
		end else begin
			if (state == `STATE_READ_INSN) begin
				// signal that we want to read the next instruction
				register_IP <= register_IP + 1;
				bus_address_out <= register_IP;
				bus_read <= 1;
				state <= `STATE_WAIT_FOR_BUS_INSN;
			end else if (state == `STATE_WAIT_FOR_BUS_INSN) begin
				if (bus_done) begin
					bus_read <= 0;
					current_insn <= bus_data_in;
					state <= `STATE_EXEC;
				end
			end else if (state == `STATE_EXEC) begin
				// instruction gets decoded by cpu_decoder module
				// based on http://www.z80.info/decoding.htm

				if (insn_x == 2'd0) begin
					if (insn_z == 3'd0) begin
						// NOP
						state <= `STATE_READ_INSN;
					end else if (insn_z == 3'd6) begin
						// LD r[y], n

						// ok, we need to read the next byte
						register_IP <= register_IP + 1;
						bus_address_out <= register_IP;
						bus_read <= 1;
						state <= `STATE_WAIT_FOR_BUS_DATA;

						target_register <= insn_y;
					end else begin
						state <= `STATE_READ_INSN;
					end
				end else begin
					state <= `STATE_READ_INSN;
				end
			end else if (state == `STATE_WAIT_FOR_BUS_DATA) begin
				if (bus_done) begin
					bus_read <= 0;

					// we have the data
					// load it into the target register
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

					state <= `STATE_READ_INSN;
				end
			end
		end
	end

endmodule
