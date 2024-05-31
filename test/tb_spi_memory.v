`default_nettype none

`define COMMAND_SIO_READ 8'h03

`define STATE_COMMAND 3'h0
`define STATE_ADDR_1 3'h1
`define STATE_ADDR_2 3'h2
`define STATE_ADDR_3 3'h3
`define STATE_DATA 3'h4

module tb_spi_memory(
	input wire spi_clk,
	input wire spi_mosi,
	output reg spi_miso,
	input wire spi_ce
);

	reg [7:0] command = 0;
	reg [23:0] address = 24'h000000;

	reg [2:0] state = `STATE_COMMAND;

	reg [3:0] bit_counter = 0;

	reg [7:0] data_array [0:7];
	reg [7:0] data = 8'h00;

	initial begin
		data_array[0] = 8'h01;
		data_array[1] = 8'h02;
		data_array[2] = 8'h03;
		data_array[3] = 8'h04;
		data_array[4] = 8'h05;
		data_array[5] = 8'h06;
		data_array[6] = 8'h07;
		data_array[7] = 8'h08;
	end

	always @(posedge spi_clk) begin
		if (!spi_ce) begin
			case (state)
				`STATE_COMMAND: begin
					spi_miso <= 1'b0;
					command <= {command[6:0], spi_mosi};
					bit_counter <= bit_counter + 1;
					if (bit_counter == 7) begin
						bit_counter <= 0;
						state <= `STATE_ADDR_1;
					end
				end
				`STATE_ADDR_1: begin
					address[23:16] <= {address[22:16], spi_mosi};
					bit_counter <= bit_counter + 1;
					if (bit_counter == 7) begin
						bit_counter <= 0;
						state <= `STATE_ADDR_2;
					end
				end
				`STATE_ADDR_2: begin
					address[15:8] <= {address[14:8], spi_mosi};
					bit_counter <= bit_counter + 1;
					if (bit_counter == 7) begin
						bit_counter <= 0;
						state <= `STATE_ADDR_3;
					end
				end
				`STATE_ADDR_3: begin
					address[7:0] = {address[6:0], spi_mosi};
					bit_counter <= bit_counter + 1;
					if (bit_counter == 7) begin
						bit_counter <= 0;
						state <= `STATE_DATA;
						data <= data_array[address];
					end
				end
				`STATE_DATA: begin
					if (command == `COMMAND_SIO_READ) begin
						// read data
						spi_miso <= data[7];
						data <= {data[6:0], 1'b0};
						bit_counter <= bit_counter + 1;

						if (bit_counter == 7) begin
							bit_counter <= 0;
							// move to the next byte
							address = address + 1;
							data <= data_array[address];
						end
					end else begin
						// write data
					end
				end
			endcase
		end else begin
			state <= `STATE_COMMAND;
		end
	end

endmodule