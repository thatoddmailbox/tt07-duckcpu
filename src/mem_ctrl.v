`default_nettype none

`define STATE_IDLE 3'h0
`define STATE_SPI_START 3'h1
`define STATE_SPI_WAIT 3'h2
`define STATE_SPI_DONE 3'h3
`define STATE_DUMMY_CLK 3'h4

module mem_ctrl(
	input wire clk,
	input wire rst_n,

	input wire [15:0] bus_address,
	input wire [7:0] bus_data_tx,
	output reg [7:0] bus_data_rx,
	input wire bus_read,
	input wire bus_write,
	output reg bus_wait,

	output wire [7:0] spi_data_tx,
	input wire [7:0] spi_data_rx,
	output reg spi_txn_start,
	input wire spi_txn_done,
	output reg spi_force_clock,
	output wire spi_flash_ce_n,
	output wire spi_ram_ce_n
);

	reg [2:0] counter;

	reg [2:0] state;

	assign spi_data_tx = (
		(counter == 0) ? 8'h03 :
		(counter == 1) ? 8'h00 :
		(counter == 2) ? bus_address[15:8] :
		(counter == 3) ? bus_address[7:0] :
		8'h00
	);

	wire ram_access = bus_address[15];
	wire bus_access = (bus_read || bus_write);

	assign spi_flash_ce_n = !(bus_access && !ram_access && state != `STATE_DUMMY_CLK);
	assign spi_ram_ce_n = !(bus_access && ram_access && state != `STATE_DUMMY_CLK);

	always @(posedge clk) begin
		if (!rst_n) begin
			bus_data_rx <= 8'h00;
			bus_wait <= 1'b1;

			counter <= 3'h0;

			state <= `STATE_IDLE;

			spi_txn_start <= 1'b0;
			spi_force_clock <= 1'b0;
			// spi_data_tx <= 8'h00;
		end else begin
			if (state == `STATE_IDLE) begin
				bus_wait <= 1'b1;

				if (bus_access) begin
					state <= `STATE_SPI_START;
					spi_txn_start <= 1'b1;
				end
			end else if (state == `STATE_SPI_START) begin
				if (!spi_txn_done) begin
					spi_txn_start <= 1'b0;
					state <= `STATE_SPI_WAIT;
				end
			end else if (state == `STATE_SPI_WAIT) begin
				if (spi_txn_done) begin
					// we should move onto the next byte
					counter <= counter + 1;

					if (counter == 4) begin
						// we finished the transmission, we have the data
						bus_wait <= 1'b0;
						bus_data_rx <= spi_data_rx;
						state <= `STATE_DUMMY_CLK;
						spi_force_clock <= 1'b1;
						counter <= 3'h0;
					end else begin
						state <= `STATE_SPI_START;
						spi_txn_start <= 1'b1;
					end
				end
			end else if (state == `STATE_DUMMY_CLK) begin
				// TODO: should only insert this if we actually want to change addr
				if (spi_txn_done) begin
					spi_force_clock <= 1'b0;
					state <= `STATE_IDLE;
				end
			end
		end
	end

endmodule
