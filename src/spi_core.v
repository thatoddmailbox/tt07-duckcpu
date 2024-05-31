`default_nettype none

module spi_core(
	input wire clk,
	input wire rst_n,

	input wire [4:0] divider,

	output reg spi_clk,
	output reg spi_mosi,
	input wire spi_miso,

	input wire [7:0] data_tx,
	output reg [7:0] data_rx,
	input wire txn_start,
	output wire txn_done,
	input wire force_clock
);

	reg [4:0] counter;

	reg [7:0] tx_buf;
	reg active;
	reg [2:0] bit_count;

	reg forcing_clock;

	assign txn_done = !active;

	always @(posedge clk) begin
		if (!rst_n) begin
			tx_buf <= 8'h00;
			active <= 1'b0;
			bit_count <= 3'b0;

			forcing_clock <= 1'b0;

			counter <= 0;

			data_rx <= 8'h00;

			spi_clk <= 1'b0;
			spi_mosi <= 1'b0;
		end else begin
			if (!active) begin
				if (txn_start) begin
					tx_buf <= data_tx;
					active <= 1'b1;
					bit_count <= 3'b0;
				end else if (force_clock) begin
					active <= 1'b1;
					forcing_clock <= 1'b1;
				end
			end else begin
				counter <= counter + 1;

				if (counter == divider) begin
					spi_clk <= ~spi_clk;
					counter <= 0;

					if (forcing_clock) begin
						if (spi_clk) begin
							// we did it, go back to normal
							active <= 1'b0;
							forcing_clock <= 1'b0;
						end
					end else begin
						if (spi_clk == 1'b0) begin
							// we just made the clk go up, so we should shift out the next bit
							// TODO: cpha bit???
							tx_buf <= {tx_buf[6:0], 1'b0};
							spi_mosi <= tx_buf[7];
							bit_count <= bit_count + 1;
						end else begin
							// we just made the clk go down, so we should read in the next bit
							data_rx <= {data_rx[6:0], spi_miso};
							if (bit_count == 3'h0) begin
								active <= 1'b0;
							end
						end
					end
				end
			end
		end
	end

endmodule
