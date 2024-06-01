`default_nettype none

module bootloader(
	input wire clk,
	input wire rst_n,

	output wire [7:0] spi_data_tx,
	input wire [7:0] spi_data_rx,
	output reg spi_txn_start,
	input wire spi_txn_done,
	output reg spi_force_clock,

	output wire spi_flash_ce_n,
	output wire spi_ram_ce_n,

	output wire [11:0] uart_divider,

	output reg [7:0] uart_data_tx,
	output reg uart_have_data_tx,
	input wire uart_transmitting,

	input wire [7:0] uart_data_rx,
	input wire uart_have_data_rx,
	output reg uart_data_rx_ack
);

	// TODO: lol xd
	assign uart_divider = 434; // 115200 baud @ 50 MHz system clock

	always @(posedge clk) begin

	end

endmodule