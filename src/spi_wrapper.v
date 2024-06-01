`default_nettype none

`define REGISTER_CONTROL 2'h0
`define REGISTER_DATA 2'h1
`define REGISTER_DIVIDER 2'h2

module spi_wrapper(
	input wire clk,
	input wire rst_n,

	input wire [1:0] bus_address,
	input wire [7:0] bus_data_tx,
	output wire [7:0] bus_data_rx,
	input wire bus_read,
	input wire bus_write,
	output wire bus_wait,

	output reg [7:0] spi_divider,

	output reg [7:0] spi_data_tx,
	input wire [7:0] spi_data_rx,
	output reg spi_txn_start,
	input wire spi_txn_done,
	output reg spi_force_clock,
	output reg spi_ce_n
);

	assign bus_wait = 1'b0;

	wire [7:0] status_register = {
		spi_txn_done,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		spi_ce_n
	};

	// TODO: implement divider
	assign bus_data_rx = (bus_address == `REGISTER_CONTROL) ? status_register :
		(bus_address == `REGISTER_DATA) ? spi_data_rx :
		(bus_address == `REGISTER_DIVIDER) ? spi_divider[7:0] :
		8'h00;

	always @(posedge clk) begin
		if (!rst_n) begin
			spi_divider <= 25;

			spi_data_tx <= 8'h00;
			spi_txn_start <= 1'b0;
			spi_force_clock <= 1'b0;
			spi_ce_n <= 1'b1;
		end else begin
			// these signals are only supposed to exist for one cycle
			if (spi_txn_start) begin
				spi_txn_start <= 1'b0;
			end
			if (spi_force_clock) begin
				spi_force_clock <= 1'b0;
			end

			if (bus_write) begin
				case (bus_address)
					`REGISTER_CONTROL: begin
						spi_ce_n <= bus_data_tx[0];
						spi_force_clock <= bus_data_tx[1];
					end
					`REGISTER_DATA: begin
						if (spi_txn_done) begin
							spi_data_tx <= bus_data_tx;
							spi_txn_start <= 1'b1;
						end
					end
					`REGISTER_DIVIDER: begin
						spi_divider[7:0] <= bus_data_tx;
					end
				endcase
			end
		end
	end

endmodule
