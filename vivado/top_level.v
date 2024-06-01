`default_nettype none

module top_level(
	input wire clk_100mhz,

    input wire uart_txd_in,
    output wire uart_rxd_out,

	input wire ck_io0,
	input wire ck_io1,
	input wire ck_io2,
	input wire ck_io3,
	input wire ck_io4,
	input wire ck_io5,
	input wire ck_io6,
	input wire ck_io7,

	output wire ck_io26,
	output wire ck_io27,
	output wire ck_io28,
	output wire ck_io29,
	output wire ck_io30,
	output wire ck_io31,
	output wire ck_io32,
	output wire ck_io33,

	output wire ck_io34,
	output wire ck_io35,
	output wire ck_io36,
	output wire ck_io37,
	output wire ck_io38,
	output wire ck_io39,
	output wire ck_io40,
	output wire ck_io41
);

	wire uart0_txd_out;

	assign uart_rxd_out = uart0_txd_out; //uo_out[3];
	assign ck_io29 = uart0_txd_out;

	wire clk_50mhz;
	clk_wiz_0 clk_inst(
		.clk_in1(clk_100mhz),
		.clk_out1(clk_50mhz)
	);

	reg [4:0] reset_counter = 0;
	reg rst_n = 1'b0;

	always @(posedge clk_50mhz) begin
		if (reset_counter == 20) begin
			rst_n <= 1'b1;
		end else begin
			reset_counter <= reset_counter + 1;
		end
	end

	// TODO fix uio stuff
	tt_um_thatoddmailbox tt_module(
		.ui_in({ck_io7, ck_io6, ck_io5, ck_io4, ck_io3, ck_io2, ck_io1, ck_io0}),
		.uo_out({ck_io33, ck_io32, ck_io31, ck_io30, uart0_txd_out, ck_io28, ck_io27, ck_io26}),
		.uio_in(8'h00),
		.uio_out({ck_io41, ck_io40, ck_io39, ck_io38, ck_io37, ck_io36, ck_io35, ck_io34}),
		.uio_oe(),
		.ena(1'b1),
		.clk(clk_50mhz),
		.rst_n(rst_n)
	);

endmodule
