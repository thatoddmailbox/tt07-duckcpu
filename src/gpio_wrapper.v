`default_nettype none

`define REGISTER_DIRECTION 1'h0
`define REGISTER_DATA 1'h1

module gpio_wrapper(
	input wire clk,
	input wire rst_n,

	input wire bus_address,
	input wire [7:0] bus_data_tx,
	output wire [7:0] bus_data_rx,
	input wire bus_read,
	input wire bus_write,
	output wire bus_wait,

	input wire [7:0] gpio_in,
	output reg [7:0] gpio_out,
	output reg [7:0] gpio_direction
);

	assign bus_wait = 1'b0;

	assign bus_data_rx = (bus_address == `REGISTER_DIRECTION) ? gpio_direction :
		(bus_address == `REGISTER_DATA) ? gpio_in :
		8'h00;

	always @(posedge clk) begin
		if (!rst_n) begin
			gpio_out <= 8'h00;
			gpio_direction <= 8'h00; // all input
		end else begin
			if (bus_write) begin
				case (bus_address)
					`REGISTER_DIRECTION: begin
						gpio_direction <= bus_data_tx;
					end
					`REGISTER_DATA: begin
						gpio_out <= bus_data_tx;
					end
				endcase
			end
		end
	end

endmodule
