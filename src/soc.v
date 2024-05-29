`default_nettype none

module soc(
	input wire clk,
	input wire rst_n,

	output wire spi_clk,
	output wire spi_mosi,
	input wire spi_miso
);

	wire [15:0] bus_address_out;
	wire [7:0] bus_data_out;
	reg [7:0] bus_data_in;
	wire bus_read;
	wire bus_write;
	wire bus_wait;

	cpu cpu_inst(
		.clk(clk),
		.rst_n(rst_n),
		.bus_address_out(bus_address_out),
		.bus_data_out(bus_data_out),
		.bus_data_in(bus_data_in),
		.bus_read(bus_read),
		.bus_write(bus_write),
		.bus_wait(bus_wait)
	);

	wire [7:0] rspi_data_tx;
	wire [7:0] rspi_data_rx;
	wire rspi_txn_start;
	wire rspi_txn_done;

	spi_core spi_inst(
		.clk(clk),
		.rst_n(rst_n),
		.spi_clk(spi_clk),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.data_tx(8'hA5),
		.data_rx(),
		.txn_start(1'b1),
		.txn_done()
	);

	// memory map
	// 0x0000 - 0x7FFF: SPI flash
	// 0x8000 - 0xFEFF: SPI RAM
	// 0xFF00 - 0xFFFF: register space
	wire bus_access_register = (bus_address_out[15:8] == 8'hFF);

	wire memory_bus_wait;
	wire [7:0] memory_bus_in;

	wire register_bus_data_in = 8'h00;
	wire register_bus_wait = 1'b0;

	mem_ctrl mem_inst(
		.clk(clk),
		.rst_n(rst_n),

		.bus_address(bus_address_out),
		.bus_data_tx(bus_data_out),
		.bus_data_rx(memory_bus_in),
		.bus_read(bus_read & !bus_access_register),
		.bus_write(bus_write & !bus_access_register),
		.bus_wait(memory_bus_wait),

		.spi_data_tx(rspi_data_tx),
		.spi_data_rx(rspi_data_rx),
		.spi_txn_start(rspi_txn_start),
		.spi_txn_done(rspi_txn_done)
	);

	assign bus_data_in = (bus_access_register ? register_bus_data_in : memory_bus_in);
	assign bus_wait = (bus_access_register ? register_bus_wait : memory_bus_wait);

	always @(posedge clk) begin
		if (!rst_n) begin
			// reset stuff
			// bus_completed <= 0;
		end else begin
			// if (bus_read) begin
			// 	// read from bus

			// 	// // TODO: something more fun
			// 	// if (bus_address_out == 16'd0) begin
			// 	// 	bus_data_in <= 8'h3E; // LD A, d8
			// 	// end else if (bus_address_out == 16'd1) begin
			// 	// 	bus_data_in <= 8'h3;
			// 	// end else if (bus_address_out == 16'd2) begin
			// 	// 	bus_data_in <= 8'h26; // LD H, d8
			// 	// end else if (bus_address_out == 16'd3) begin
			// 	// 	bus_data_in <= 8'hFF;
			// 	// end else if (bus_address_out == 16'd4) begin
			// 	// 	bus_data_in <= 8'h2E; // LD L, d8
			// 	// end else if (bus_address_out == 16'd5) begin
			// 	// 	bus_data_in <= 8'h00;
			// 	// end else if (bus_address_out == 16'd6) begin
			// 	// 	bus_data_in <= 8'h3D; // DEC A
			// 	// end else if (bus_address_out == 16'd7) begin
			// 	// 	bus_data_in <= 8'h77; // LD [HL], A
			// 	// end else if (bus_address_out == 16'd8) begin
			// 	// 	bus_data_in <= 8'hC2; // JP nz, a16
			// 	// end else if (bus_address_out == 16'd9) begin
			// 	// 	bus_data_in <= 8'h06; // lower byte
			// 	// end else if (bus_address_out == 16'd10) begin
			// 	// 	bus_data_in <= 8'h00; // upper byte
			// 	// end else begin
			// 	// 	bus_data_in <= 8'h00; // NOP
			// 	// end

			// 	bus_completed <= 1;
			// end else if (bus_write) begin
			// 	// write to bus

			// 	// TODO: don't just ignore it

			// 	bus_completed <= 1;
			// end else begin
			// 	bus_completed <= 0;
			// end
		end
	end

endmodule
