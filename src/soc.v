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
	reg bus_done;

	cpu cpu_inst(
		.clk(clk),
		.rst_n(rst_n),
		.bus_address_out(bus_address_out),
		.bus_data_out(bus_data_out),
		.bus_data_in(bus_data_in),
		.bus_read(bus_read),
		.bus_write(bus_write),
		.bus_done(bus_done)
	);

	reg waiting_for_bus_completion = 0;

	always @(posedge clk) begin
		if (!rst_n) begin
			// reset stuff
		end else begin
			if (waiting_for_bus_completion) begin
				// wait for the read or write signal to go away
				// this means that the CPU has processed the bus data
				// and therefore we can reset the bus_done signal
				if (!bus_read && !bus_write) begin
					waiting_for_bus_completion <= 0;
					bus_done <= 0;
				end
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
					bus_done <= 1;

					waiting_for_bus_completion <= 1;
				end else if (bus_write) begin
					// write to bus

					// TODO: don't just ignore it
					bus_done <= 1;

					waiting_for_bus_completion <= 1;
				end
			end
		end
	end

endmodule
