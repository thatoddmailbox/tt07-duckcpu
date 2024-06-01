`default_nettype none

// note how COMMAND_PING is ASCII 'p' and COMMAND_RESET is ASCII 'R'

`define COMMAND_PING 8'h70
`define COMMAND_RESET 8'h52
`define COMMAND_TRANSMIT 8'h90
`define COMMAND_TARGET_FLASH 8'hA0
`define COMMAND_TARGET_RAM 8'hB1
`define COMMAND_FORCE_CLOCK 8'h91

`define RESPONSE_PONG 8'h50
`define RESPONSE_OK 8'h71
`define RESPONSE_ERROR 8'h45
`define RESPONSE_TRANSMIT_READY_FOR_COUNT 8'h91
`define RESPONSE_TRANSMIT_READY_FOR_DATA 8'h92

`define STATE_COMMAND 2'h0
`define STATE_TRANSMIT_WAIT_FOR_COUNT 2'h1
`define STATE_TRANSMIT_WAIT_FOR_DATA 2'h2
`define STATE_TRANSMIT_WAIT_FOR_SPI 2'h3

`define BUFFER_SIZE 5

module bootloader(
	input wire clk,
	input wire rst_n,

	input wire active,

	output reg [7:0] spi_data_tx,
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

	reg [1:0] state;
	reg [7:0] transmit_index;
	reg [7:0] transmit_count;

	reg target_flash;
	reg transmitting;

	reg [7:0] transmit_buffer [0:(`BUFFER_SIZE-1)];

	reg just_handled_rx;
	reg spi_started;

	wire spi_ce = (state == `STATE_TRANSMIT_WAIT_FOR_SPI);
	wire spi_ce_n = ~spi_ce;
	assign spi_flash_ce_n = target_flash ? spi_ce_n : 1'b1;
	assign spi_ram_ce_n = target_flash ? 1'b1 : spi_ce_n;

	always @(posedge clk) begin
		if (!rst_n) begin
			spi_data_tx <= 8'h00;
			spi_txn_start <= 1'b0;
			spi_force_clock <= 1'b0;

			target_flash <= 1'b1;
			transmitting <= 1'b0;

			uart_data_tx <= 8'h00;
			uart_have_data_tx <= 1'b0;
			uart_data_rx_ack <= 1'b0;

			state <= `STATE_COMMAND;
			transmit_index <= 8'h00;
			transmit_count <= 8'h00;
			just_handled_rx <= 1'b0;
			spi_started <= 1'b0;

			// TODO: make this into a loop lol
			transmit_buffer[0] <= 8'h00;
			transmit_buffer[1] <= 8'h00;
			transmit_buffer[2] <= 8'h00;
			transmit_buffer[3] <= 8'h00;
			transmit_buffer[4] <= 8'h00;
		end else if (active) begin
			if (uart_have_data_rx && !just_handled_rx && !uart_transmitting) begin
				uart_data_rx_ack <= 1'b1;
				just_handled_rx <= 1'b1;

				if (state == `STATE_COMMAND) begin
					if (uart_data_rx == `COMMAND_PING) begin
						uart_data_tx <= `RESPONSE_PONG;
						uart_have_data_tx <= 1'b1;
					end else if (uart_data_rx == `COMMAND_RESET) begin
						// TODO: what do
					end else if (uart_data_rx == `COMMAND_TARGET_FLASH) begin
						target_flash <= 1'b1;

						uart_data_tx <= `RESPONSE_OK;
						uart_have_data_tx <= 1'b1;
					end else if (uart_data_rx == `COMMAND_TARGET_RAM) begin
						target_flash <= 1'b0;

						uart_data_tx <= `RESPONSE_OK;
						uart_have_data_tx <= 1'b1;
					end else if (uart_data_rx == `COMMAND_TRANSMIT) begin
						state <= `STATE_TRANSMIT_WAIT_FOR_COUNT;

						uart_data_tx <= `RESPONSE_TRANSMIT_READY_FOR_COUNT;
						uart_have_data_tx <= 1'b1;
					end else if (uart_data_rx == `COMMAND_FORCE_CLOCK) begin
						spi_force_clock <= 1'b1;

						uart_data_tx <= `RESPONSE_OK;
						uart_have_data_tx <= 1'b1;
					end else begin
						uart_data_tx <= `RESPONSE_ERROR;
						uart_have_data_tx <= 1'b1;
					end
				end else if (state == `STATE_TRANSMIT_WAIT_FOR_COUNT) begin
					if (uart_data_rx <= `BUFFER_SIZE) begin
						transmit_index <= 8'h00;
						transmit_count <= uart_data_rx;
						state <= `STATE_TRANSMIT_WAIT_FOR_DATA;

						uart_data_tx <= `RESPONSE_TRANSMIT_READY_FOR_DATA;
						uart_have_data_tx <= 1'b1;
					end else begin
						state <= `STATE_COMMAND;

						uart_data_tx <= `RESPONSE_ERROR;
						uart_have_data_tx <= 1'b1;
					end
				end else if (state == `STATE_TRANSMIT_WAIT_FOR_DATA) begin
					transmit_buffer[transmit_index] <= uart_data_rx;
					transmit_index <= transmit_index + 1;

					uart_data_tx <= `RESPONSE_OK;
					uart_have_data_tx <= 1'b1;

					if ((transmit_index + 1) == transmit_count) begin
						state <= `STATE_TRANSMIT_WAIT_FOR_SPI;
						transmit_index <= 0;

						spi_data_tx <= transmit_buffer[0];
						spi_txn_start <= 1'b1;
						spi_started <= 1'b0;
					end
				end
			end

			if (state == `STATE_TRANSMIT_WAIT_FOR_SPI) begin
				if (spi_started) begin
					if (spi_txn_done) begin
						transmit_count <= transmit_count - 1;

						transmit_buffer[transmit_index] <= spi_data_rx;

						// uart_data_tx <= spi_data_rx;
						// uart_have_data_tx <= 1'b1;

						if (transmit_count == 8'h01) begin
							// that was the last byte, we're done
							// TODO: tell computer response data
							state <= `STATE_COMMAND;

							uart_data_tx <= `RESPONSE_OK;
							uart_have_data_tx <= 1'b1;
						end else begin
							// still have more bytes to transmit
							state <= `STATE_TRANSMIT_WAIT_FOR_SPI;

							spi_data_tx <= transmit_buffer[transmit_index + 1];
							transmit_index <= transmit_index + 1;
							spi_txn_start <= 1'b1;
							spi_started <= 1'b0;
						end
					end
				end else begin
					if (!spi_txn_done) begin
						spi_txn_start <= 1'b0;
						spi_started <= 1'b1;
					end
				end
			end

			if (just_handled_rx) begin
				just_handled_rx <= 1'b0;
			end

			if (spi_txn_start) begin
				spi_txn_start <= 1'b0;
			end

			if (spi_force_clock) begin
				spi_force_clock <= 1'b0;
			end

			if (uart_data_rx_ack) begin
				uart_data_rx_ack <= 1'b0;
			end

			if (uart_have_data_tx) begin
				uart_have_data_tx <= 1'b0;
			end
		end
	end

endmodule
