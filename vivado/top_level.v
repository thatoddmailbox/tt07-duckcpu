`default_nettype none

module top_level(
	input wire clk_100mhz,

    input wire uart_txd_in,
    output wire uart_rxd_out
);

	assign uart_rxd_out = uart_txd_in;

endmodule
