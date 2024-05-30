`default_nettype none

module spi_core(
	input wire clk,
	input wire rst_n,

	output reg spi_clk,
	output reg spi_mosi,
	input wire spi_miso,

	input wire [7:0] data_tx,
	output reg [7:0] data_rx,
	input wire txn_start,
	output wire txn_done
);

	reg [7:0] tx_buf;
	reg active;
	reg [2:0] bit_count;

	assign txn_done = !active;

	always @(posedge clk) begin
		if (!rst_n) begin
			tx_buf <= 8'h00;
			active <= 1'b0;
			bit_count <= 3'b0;

			data_rx <= 8'h00;

			spi_clk <= 1'b0;
			spi_mosi <= 1'b0;
		end else begin
			if (!active) begin
				if (txn_start) begin
					tx_buf <= data_tx;
					active <= 1'b1;
					bit_count <= 3'b0;
				end
			end else begin
				spi_clk <= ~spi_clk;
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

endmodule
