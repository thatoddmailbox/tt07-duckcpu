`default_nettype none

module spi_core(
	input wire clk,
	input wire rst_n,

	output reg spi_clk,
	output reg spi_mosi,
	input wire spi_miso,

	input wire [7:0] data_tx,
	output reg [7:0] data_rx,
	input wire have_data,
	output wire txn_done
);

	reg [7:0] tx_buf;
	reg active;

	assign txn_done = !active;

	always @(posedge clk) begin
		if (!rst_n) begin
			tx_buf <= 8'h00;
			active <= 1'b0;

			spi_clk <= 1'b0;
			spi_mosi <= 1'b0;
		end else begin
			if (!active) begin
				if (have_data) begin
					tx_buf <= data_tx;
					active <= 1'b1;
				end
			end else begin
				spi_clk <= ~spi_clk;
				if (spi_clk == 1'b0) begin
					// we just made the clk go up, so we should shift out the next bit
					// TODO: cpha bit???
					tx_buf <= {tx_buf[6:0], 1'b0};
					spi_mosi <= tx_buf[7];
				end
			end
		end
	end

endmodule
