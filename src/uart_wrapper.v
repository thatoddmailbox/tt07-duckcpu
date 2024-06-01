`default_nettype none

`define REGISTER_STATUS 2'h0
`define REGISTER_DATA 2'h1
`define REGISTER_DIVIDER_LOW 2'h2
`define REGISTER_DIVIDER_HIGH 2'h3

module uart_wrapper(
	input wire clk,
	input wire rst_n,

	input wire [1:0] bus_address,
	input wire [7:0] bus_data_tx,
	output wire [7:0] bus_data_rx,
	input wire bus_read,
	input wire bus_write,
	output wire bus_wait,

	output reg [11:0] uart_divider,

	output reg [7:0] uart_data_tx,
	output reg uart_have_data_tx,
	input wire uart_transmitting,

	input wire [7:0] uart_data_rx,
	input wire uart_have_data_rx,
	output reg uart_data_rx_ack
);

	assign bus_wait = 1'b0;

	wire [7:0] status_register = {
		uart_have_data_rx,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		uart_transmitting
	};

	// TODO: implement divider
	assign bus_data_rx = (bus_address == `REGISTER_STATUS) ? status_register :
		(bus_address == `REGISTER_DATA) ? uart_data_rx :
		(bus_address == `REGISTER_DIVIDER_LOW) ? uart_divider[7:0] :
		(bus_address == `REGISTER_DIVIDER_HIGH) ? {4'h0, uart_divider[11:8]} :
		8'h00;

	always @(posedge clk) begin
		if (!rst_n) begin
			// TODO: would be cool if we could support autobauding
			// this would be useful for the bootloader
			uart_divider <= 434; // 115200 baud @ 50 MHz system clock

			uart_data_tx <= 8'h00;
			uart_have_data_tx <= 1'b0;
			uart_data_rx_ack <= 1'b0;
		end else begin
			if (bus_read) begin
				// read values are handled by the assign statement above
				// this just ensures that we acknowledge the read

				if (bus_address == `REGISTER_DATA) begin
					uart_data_rx_ack <= 1'b1;
				end
			end

			// these signals are only supposed to exist for one cycle
			if (uart_have_data_tx && uart_transmitting) begin
				uart_have_data_tx <= 1'b0;
			end
			if (uart_data_rx_ack) begin
				uart_data_rx_ack <= 1'b0;
			end

			if (bus_write) begin
				case (bus_address)
					`REGISTER_STATUS: begin
						// ignore
					end
					`REGISTER_DATA: begin
						if (!uart_transmitting) begin
							uart_data_tx <= bus_data_tx;
							uart_have_data_tx <= 1'b1;
						end
					end
					`REGISTER_DIVIDER_LOW: begin
						uart_divider[7:0] <= bus_data_tx;
					end
					`REGISTER_DIVIDER_HIGH: begin
						uart_divider[11:8] <= bus_data_tx[3:0];
					end
				endcase
			end
		end
	end

endmodule
