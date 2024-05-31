`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  tt_um_thatoddmailbox user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  tb_spi_memory virtual_flash(
    .spi_clk(uo_out[6]),
    .spi_mosi(uo_out[5]),
    .spi_miso(ui_in[7]),
    .spi_ce(uo_out[7])
  );

  // wire [15:0] bus_address_out;
	// wire [7:0] bus_data_out;
	// reg [7:0] bus_data_in;
	// wire bus_read;
	// wire bus_write;
	// reg bus_wait;

  // cpu cpu_inst(
  //   .clk(clk),
  //   .rst_n(rst_n),

  //   .bus_address_out(bus_address_out),
  //   .bus_data_out(bus_data_out),
  //   .bus_data_in(bus_data_in),
  //   .bus_read(bus_read),
  //   .bus_write(bus_write),
  //   .bus_wait(bus_wait)
  // );

endmodule
