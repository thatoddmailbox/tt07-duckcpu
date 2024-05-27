`default_nettype none

module soc(
	input wire clk,
	input wire rst_n
);

	wire [15:0] bus_address_out;
	wire [7:0] bus_data_out;
	reg [7:0] bus_data_in;
	wire bus_read;
	wire bus_write;
	reg bus_wait;

	reg bus_completed;

	cpu cpu_inst(
		.clk(clk),
		.rst_n(rst_n),
		.bus_address_out(bus_address_out),
		.bus_data_out(bus_data_out),
		.bus_data_in(bus_data_in),
		.bus_read(bus_read),
		.bus_write(bus_write),
		.bus_wait(!bus_completed)
	);

	always @(posedge clk) begin
		if (!rst_n) begin
			// reset stuff
			bus_wait <= 0;
			bus_completed <= 0;
		end else begin
			if (bus_read) begin
				// read from bus

				// TODO: something more fun
				if (bus_address_out == 16'd0) begin
					bus_data_in <= 8'h3E; // LD A, d8
				end else if (bus_address_out == 16'd1) begin
					bus_data_in <= 8'h55;
				end else if (bus_address_out == 16'd2) begin
					bus_data_in <= 8'h3C; // INC A
				end else begin
					bus_data_in <= 8'h00; // NOP
				end

				bus_completed <= 1;
			end else if (bus_write) begin
				// write to bus

				// TODO: don't just ignore it

				bus_completed <= 1;
			end else begin
				bus_completed <= 0;
			end
		end
	end

endmodule
