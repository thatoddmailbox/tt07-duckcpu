`default_nettype none

`define STATE_START 2'h0
`define STATE_DATA 2'h1
`define STATE_STOP 2'h2
`define STATE_DONE 2'h3

module uart_core(
	input wire clk,
	input wire rst_n,

	input wire rxd_in,
	output reg txd_out,

	input wire [11:0] divider,

	input wire [7:0] data_tx,
	input wire have_data_tx,
	output wire transmitting,

	output reg [7:0] data_rx,
	output reg have_data_rx,
	input wire data_rx_ack
);

	reg [11:0] tx_counter;

	reg [7:0] tx_buf;
	reg tx_active;
	reg [3:0] tx_bit_count;

	reg [1:0] tx_state;

	assign transmitting = tx_active;

	reg [11:0] rx_counter;

	reg [7:0] rx_buf;
	reg rx_active;
	reg [3:0] rx_bit_count;

	reg [1:0] rx_state;

	always @(posedge clk) begin
		if (!rst_n) begin
			txd_out <= 1'b1;
			data_rx <= 8'h00;
			have_data_rx <= 1'b0;

			tx_counter <= 0;

			tx_buf <= 8'h00;
			tx_active <= 1'b0;
			tx_bit_count <= 4'h0;

			tx_state <= `STATE_START;

			rx_counter <= 0;

			rx_buf <= 8'h00;
			rx_active <= 1'b0;
			rx_bit_count <= 4'h0;

			rx_state <= `STATE_DATA;
		end else begin
			//
			// transmitter
			//
			if (tx_active) begin
				tx_counter <= tx_counter + 1;

				if (tx_counter == divider) begin
					tx_counter <= 0;

					case (tx_state)
						`STATE_START: begin
							txd_out <= 1'b0;
							tx_state <= `STATE_DATA;
						end
						`STATE_DATA: begin
							txd_out <= tx_buf[0];
							tx_buf <= {1'b0, tx_buf[7:1]};
							tx_bit_count <= tx_bit_count + 1;

							if (tx_bit_count == 7) begin
								tx_state <= `STATE_STOP;
							end
						end
						`STATE_STOP: begin
							txd_out <= 1'b1;
							tx_state <= `STATE_DONE;
						end
						`STATE_DONE: begin
							tx_active <= 1'b0;
							tx_state <= `STATE_START;
						end
					endcase
				end
			end else if (have_data_tx) begin
				tx_counter <= 0;

				tx_buf <= data_tx;
				tx_active <= 1'b1;
				tx_bit_count <= 4'h0;

				tx_state <= `STATE_START;

				txd_out <= 1'b1;
			end


			//
			// receiver
			//
			if (rx_active) begin
				rx_counter <= rx_counter + 1;

				if (rx_counter == divider) begin
					rx_counter <= 0;

					case (rx_state)
						`STATE_START: begin
							// should not happen
						end
						`STATE_DATA: begin
							rx_buf <= {rxd_in, rx_buf[7:1]};
							rx_bit_count <= rx_bit_count + 1;

							if (rx_bit_count == 7) begin
								rx_state <= `STATE_STOP;
							end
						end
						`STATE_STOP: begin
							if (rxd_in == 1'b1) begin
								rx_state <= `STATE_DONE;
							end
						end
						`STATE_DONE: begin
							data_rx <= rx_buf;
							have_data_rx <= 1'b1;
							rx_active <= 1'b0;
							rx_state <= `STATE_START;
						end
					endcase
				end
			end else if (rxd_in == 1'b0) begin
				// start bit!
				rx_counter <= 0;

				rx_buf <= 8'h00;
				rx_active <= 1'b1;
				rx_bit_count <= 4'h0;

				rx_state <= `STATE_DATA;
			end

			if (data_rx_ack) begin
				have_data_rx <= 1'b0;
			end
		end
	end

endmodule
