`default_nettype none

module spi_core(
	input wire clk,
	input wire rst_n,

	input wire [7:0] divider,

	output reg spi_clk,
	output reg spi_mosi,
	input wire spi_miso,

	input wire [7:0] data_tx,
	output reg [7:0] data_rx,
	input wire txn_start,
	output wire txn_done,
	input wire force_clock
);

	reg [7:0] counter;

	reg [7:0] tx_buf;
	reg active;
	reg [3:0] bit_count;

	reg forcing_clock;
	reg forcing_clock_did_first;

	assign txn_done = !active;

	always @(posedge clk) begin
		if (!rst_n) begin
			tx_buf <= 8'h00;
			active <= 1'b0;
			bit_count <= 4'b0;

			forcing_clock <= 1'b0;
			forcing_clock_did_first <= 1'b0;

			counter <= 0;

			data_rx <= 8'h00;

			spi_clk <= 1'b0;
			spi_mosi <= 1'b0;
		end else begin
			if (!active) begin
				if (txn_start) begin
					active <= 1'b1;
					bit_count <= 4'b0;

					// set mosi to the first bit, in preparation for the first rising edge
					spi_mosi <= data_tx[7];
					tx_buf <= {data_tx[6:0], 1'b0};
				end else if (force_clock) begin
					active <= 1'b1;
					forcing_clock <= 1'b1;
					forcing_clock_did_first <= 1'b0;
				end
			end else begin
				counter <= counter + 1;

				if (counter == divider) begin
					counter <= 0;

					if (!forcing_clock && spi_clk == 1'b0 && bit_count == 4'h8) begin
						// we are done
						active <= 1'b0;
					end else begin
						spi_clk <= ~spi_clk;

						if (forcing_clock) begin
							if (spi_clk == 1'b1) begin
								forcing_clock_did_first <= 1'b1;
							end else if (spi_clk == 1'b0 && forcing_clock_did_first) begin
								// we did it, go back to normal
								active <= 1'b0;
								forcing_clock <= 1'b0;
								spi_clk <= 1'b0;
							end
						end else begin
							if (spi_clk == 1'b1) begin
								// we just made the clk go down

								// read in the next bit
								// TODO: HACK: this feels wrong...we are claiming CPHA = 0, but we are kinda reading on the falling edge??
								// but also I guess this is happening before the edge falls?
								// is this legal???? probably depends on the device??? there isn't really a spi standard :(
								data_rx <= {data_rx[6:0], spi_miso};
								bit_count <= bit_count + 1;

								// shift out the next bit, in anticipation of the next rising edge
								// TODO: cpha bit???
								tx_buf <= {tx_buf[6:0], 1'b0};
								spi_mosi <= tx_buf[7];
							end
						end
					end
				end
			end
		end
	end

endmodule
