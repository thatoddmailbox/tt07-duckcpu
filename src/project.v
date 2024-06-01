`default_nettype none

module tt_um_thatoddmailbox (
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	soc soc_inst(
		.clk(clk),
		.rst_n(rst_n),

`ifdef SIM
		.bootsel(1'b1),
`else
		.bootsel(ui_in[4]),
`endif

		.rspi_clk(uo_out[0]),
		.rspi_mosi(uo_out[1]),
		.rspi_miso(ui_in[6]),
		.rspi_flash_ce_n(uo_out[2]),
		.rspi_ram_ce_n(uo_out[3]),

		.uart0_rxd_in(ui_in[7]),
		.uart0_txd_out(uo_out[4]),

		.spi0_clk(uo_out[5]),
		.spi0_mosi(uo_out[6]),
		.spi0_miso(ui_in[5]),
		.spi0_ce_n(uo_out[7]),

		.gpio_in(uio_in),
		.gpio_out(uio_out),
		.gpio_direction(uio_oe)
	);

endmodule
