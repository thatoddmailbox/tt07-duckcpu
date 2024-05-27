`default_nettype none

`define STATE_READ 2'b00
`define STATE_WAIT_FOR_BUS 2'b01
`define STATE_EXEC 2'b10

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

	reg [1:0] state;

	reg [7:0] register_A;
	reg [7:0] register_B;

	reg [15:0] register_IP;

	reg [7:0] current_insn;

	always @(posedge clk) begin
		if (!rst_n) begin
			state <= `STATE_READ;
			register_A <= 8'h00;
			register_B <= 8'h00;
			register_IP <= 16'h0000;

			bus_address_out <= 16'h0000;
			bus_data_out <= 8'h00;
			bus_read <= 0;
			bus_write <= 0;
		end else begin
			if (state == `STATE_READ) begin
				// signal that we want to read the next instruction
				register_IP <= register_IP + 1;
				bus_address_out <= register_IP;
				bus_read <= 1;
				state <= `STATE_WAIT_FOR_BUS;
			end else if (state == `STATE_WAIT_FOR_BUS) begin
				if (bus_done) begin
					bus_read <= 0;
					current_insn <= bus_data_in;
					state <= `STATE_EXEC;
				end
			end else if (state == `STATE_EXEC) begin
				// Decode and execute the instruction
				// For now, just increment register_A
				register_A <= register_A + 1;
				state <= `STATE_READ;
			end
		end
	end

endmodule