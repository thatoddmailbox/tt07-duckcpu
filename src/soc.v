`default_nettype none

module soc(
	input wire clk,
	input wire rst_n,

	input wire bootsel,

	output wire rspi_clk,
	output wire rspi_mosi,
	input wire rspi_miso,
	output wire rspi_flash_ce_n,
	output wire rspi_ram_ce_n,

	input wire uart0_rxd_in,
	output wire uart0_txd_out,

	output wire spi0_clk,
	output wire spi0_mosi,
	input wire spi0_miso,
	output wire spi0_ce_n,

	input wire [7:0] gpio_in,
	output reg [7:0] gpio_out,
	output reg [7:0] gpio_direction
);

	reg bootloader_active;

	always @(posedge clk) begin
		if (!rst_n) begin
			bootloader_active <= 1'b0;
		end else begin
			bootloader_active <= bootsel ? 1'b0 : 1'b1;
		end
	end

	//
	// main cpu
	//

	wire [15:0] bus_address_out;
	wire [7:0] bus_data_out;
	wire [7:0] bus_data_in;
	wire bus_read;
	wire bus_write;
	wire bus_wait;

	cpu cpu_inst(
		.clk(clk),
		.rst_n(rst_n),

		.active(!bootloader_active),

		.bus_address_out(bus_address_out),
		.bus_data_out(bus_data_out),
		.bus_data_in(bus_data_in),
		.bus_read(bus_read),
		.bus_write(bus_write),
		.bus_wait(bus_wait)
	);

	//
	// mapping logic
	//

	// memory map
	// 0x0000 - 0x7FFF: SPI flash
	// 0x8000 - 0xFEFF: SPI RAM
	// 0xFF00 - 0xFFFF: register space
	wire bus_access_register = (bus_address_out[15:8] == 8'hFF);
	wire bus_access_uart0 = (bus_address_out[7:4] == 4'h0);
	wire bus_access_spi0 = (bus_address_out[7:4] == 4'h1);
	wire bus_access_gpio0 = (bus_address_out[7:4] == 4'h2);

	wire memory_bus_wait;
	wire [7:0] memory_bus_in;

	wire [7:0] uart0_bus_data_rx;
	wire uart0_bus_wait;

	wire [7:0] spi0_bus_data_rx;
	wire spi0_bus_wait;

	wire [7:0] gpio0_bus_data_rx;
	wire gpio0_bus_wait;

	wire [7:0] register_bus_data_in = (
		bus_access_uart0 ? uart0_bus_data_rx :
		bus_access_spi0 ? spi0_bus_data_rx :
		bus_access_gpio0 ? gpio0_bus_data_rx :
		8'h00
	);
	wire register_bus_wait = (
		bus_access_uart0 ? uart0_bus_wait :
		bus_access_spi0 ? spi0_bus_wait :
		bus_access_gpio0 ? gpio0_bus_wait :
		1'b0
	);

	//
	// rspi (reserved SPI)
	//

	wire [7:0] rspi_data_tx;
	wire [7:0] rspi_data_rx;
	wire rspi_txn_start;
	wire rspi_txn_done;
	wire rspi_force_clock;

	spi_core rspi_inst(
		.clk(clk),
		.rst_n(rst_n),
`ifdef SIM
		.divider(8'd0),
`else
		.divider(8'd25),
`endif
		.spi_clk(rspi_clk),
		.spi_mosi(rspi_mosi),
		.spi_miso(rspi_miso),
		.data_tx(rspi_data_tx),
		.data_rx(rspi_data_rx),
		.txn_start(rspi_txn_start),
		.txn_done(rspi_txn_done),
		.force_clock(rspi_force_clock)
	);

	//
	// rspi mapping
	//

	assign rspi_data_tx = (bootloader_active ? bootloader_rspi_data_tx : memory_rspi_data_tx);
	assign rspi_txn_start = (bootloader_active ? bootloader_rspi_txn_start : memory_rspi_txn_start);
	assign rspi_force_clock = (bootloader_active ? bootloader_rspi_force_clock : memory_rspi_force_clock);

	assign rspi_flash_ce_n = (bootloader_active ? bootloader_spi_flash_ce_n : memory_spi_flash_ce_n);
	assign rspi_ram_ce_n = (bootloader_active ? bootloader_spi_ram_ce_n : memory_spi_ram_ce_n);

	//
	// memory controller
	//

	wire [7:0] memory_rspi_data_tx;
	wire memory_rspi_txn_start;
	wire memory_rspi_force_clock;

	wire memory_spi_flash_ce_n;
	wire memory_spi_ram_ce_n;

	mem_ctrl mem_ctrl_inst(
		.clk(clk),
		.rst_n(rst_n),

		.bus_address(bus_address_out),
		.bus_data_tx(bus_data_out),
		.bus_data_rx(memory_bus_in),
		.bus_read(bus_read & !bus_access_register),
		.bus_write(bus_write & !bus_access_register),
		.bus_wait(memory_bus_wait),

		.spi_data_tx(memory_rspi_data_tx),
		.spi_data_rx(!bootloader_active ? rspi_data_rx : 8'h00),
		.spi_txn_start(memory_rspi_txn_start),
		.spi_txn_done(!bootloader_active ? rspi_txn_done : 1'b0),
		.spi_force_clock(memory_rspi_force_clock),

		.spi_flash_ce_n(memory_spi_flash_ce_n),
		.spi_ram_ce_n(memory_spi_ram_ce_n)
	);

	assign bus_data_in = (bus_access_register ? register_bus_data_in : memory_bus_in);
	assign bus_wait = (bus_access_register ? register_bus_wait : memory_bus_wait);

	//
	// bootloader
	//

	wire [7:0] bootloader_rspi_data_tx;
	wire bootloader_rspi_txn_start;
	wire bootloader_rspi_force_clock;

	wire bootloader_spi_flash_ce_n;
	wire bootloader_spi_ram_ce_n;

	wire [11:0] bootloader_uart0_divider;

	wire [7:0] bootloader_uart0_data_tx;
	wire bootloader_uart0_have_data_tx;
	wire bootloader_uart0_data_rx_ack;

	bootloader bootloader_inst(
		.clk(clk),
		.rst_n(rst_n),

		.active(bootloader_active),

		.spi_data_tx(bootloader_rspi_data_tx),
		.spi_data_rx(bootloader_active ? rspi_data_rx : 8'h00),
		.spi_txn_start(bootloader_rspi_txn_start),
		.spi_txn_done(bootloader_active ? rspi_txn_done : 1'b0),
		.spi_force_clock(bootloader_rspi_force_clock),

		.spi_flash_ce_n(bootloader_spi_flash_ce_n),
		.spi_ram_ce_n(bootloader_spi_ram_ce_n),

		.uart_divider(bootloader_uart0_divider),

		.uart_data_tx(bootloader_uart0_data_tx),
		.uart_have_data_tx(bootloader_uart0_have_data_tx),
		.uart_transmitting(bootloader_active ? uart0_transmitting : 1'b0),

		.uart_data_rx(bootloader_active ? uart0_data_rx : 8'h00),
		.uart_have_data_rx(bootloader_active ? uart0_have_data_rx : 1'b0),
		.uart_data_rx_ack(bootloader_uart0_data_rx_ack)
	);

	//
	// uart0
	//

	wire uart0_transmitting;

	wire [7:0] uart0_data_rx;
	wire uart0_have_data_rx;

	uart_core uart0_inst(
		.clk(clk),
		.rst_n(rst_n),

		.rxd_in(uart0_rxd_in),
		.txd_out(uart0_txd_out),

		.divider(bootloader_active ? bootloader_uart0_divider : wrapper_uart0_divider),

		.data_tx(bootloader_active ? bootloader_uart0_data_tx : wrapper_uart0_data_tx),
		.have_data_tx(bootloader_active ? bootloader_uart0_have_data_tx : wrapper_uart0_have_data_tx),
		.transmitting(uart0_transmitting),

		.data_rx(uart0_data_rx),
		.have_data_rx(uart0_have_data_rx),
		.data_rx_ack(bootloader_active ? bootloader_uart0_data_rx_ack : wrapper_uart0_data_rx_ack)
	);

	wire [11:0] wrapper_uart0_divider;

	wire [7:0] wrapper_uart0_data_tx;
	wire wrapper_uart0_have_data_tx;
	wire wrapper_uart0_data_rx_ack;

	uart_wrapper uart0_wrapper(
		.clk(clk),
		.rst_n(rst_n),

		.bus_address(bus_address_out[1:0]),
		.bus_data_tx(bus_data_out),
		.bus_data_rx(uart0_bus_data_rx),
		.bus_read(bus_access_uart0 ? bus_read : 1'b0),
		.bus_write(bus_access_uart0 ? bus_write : 1'b0),
		.bus_wait(uart0_bus_wait),

		.uart_divider(wrapper_uart0_divider),

		.uart_data_tx(wrapper_uart0_data_tx),
		.uart_have_data_tx(wrapper_uart0_have_data_tx),
		.uart_transmitting(!bootloader_active ? uart0_transmitting : 1'b0),

		.uart_data_rx(!bootloader_active ? uart0_data_rx : 8'h00),
		.uart_have_data_rx(!bootloader_active ? uart0_have_data_rx : 1'b0),
		.uart_data_rx_ack(wrapper_uart0_data_rx_ack)
	);

	//
	// spi0
	//

	wire [7:0] spi0_divider;

	wire [7:0] spi0_data_tx;
	wire [7:0] spi0_data_rx;
	wire spi0_txn_start;
	wire spi0_txn_done;
	wire spi0_force_clock;

	spi_core spi0_inst(
		.clk(clk),
		.rst_n(rst_n),
		.divider(spi0_divider),
		.spi_clk(spi0_clk),
		.spi_mosi(spi0_mosi),
		.spi_miso(spi0_miso),
		.data_tx(spi0_data_tx),
		.data_rx(spi0_data_rx),
		.txn_start(spi0_txn_start),
		.txn_done(spi0_txn_done),
		.force_clock(spi0_force_clock)
	);

	spi_wrapper spi0_wrapper(
		.clk(clk),
		.rst_n(rst_n),

		.bus_address(bus_address_out[1:0]),
		.bus_data_tx(bus_data_out),
		.bus_data_rx(spi0_bus_data_rx),
		.bus_read(bus_access_spi0 ? bus_read : 1'b0),
		.bus_write(bus_access_spi0 ? bus_write : 1'b0),
		.bus_wait(spi0_bus_wait),

		.spi_divider(spi0_divider),

		.spi_data_tx(spi0_data_tx),
		.spi_data_rx(spi0_data_rx),
		.spi_txn_start(spi0_txn_start),
		.spi_txn_done(spi0_txn_done),
		.spi_force_clock(spi0_force_clock),
		.spi_ce_n(spi0_ce_n)
	);

	//
	// gpio0
	//

	gpio_wrapper gpio0_wrapper(
		.clk(clk),
		.rst_n(rst_n),

		.bus_address(bus_address_out[0]),
		.bus_data_tx(bus_data_out),
		.bus_data_rx(gpio0_bus_data_rx),
		.bus_read(bus_access_gpio0 ? bus_read : 1'b0),
		.bus_write(bus_access_gpio0 ? bus_write : 1'b0),
		.bus_wait(gpio0_bus_wait),

		.gpio_in(gpio_in),
		.gpio_out(gpio_out),
		.gpio_direction(gpio_direction)
	);


endmodule
