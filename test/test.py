import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

import json

@cocotb.test()
async def test_project(dut):
	dut._log.info("Start")

	# Set the clock period to 10 us (100 KHz)
	clock = Clock(dut.clk, 10, units="us")
	cocotb.start_soon(clock.start())

	# Reset
	dut._log.info("Reset")
	dut.ena.value = 1
	dut.ui_in.value = 0
	dut.uio_in.value = 0
	dut.rst_n.value = 0
	await ClockCycles(dut.clk, 5)
	dut.rst_n.value = 1

	dut._log.info("Test project behavior")

	# Set the input values you want to test
	dut.ui_in.value = 20
	dut.uio_in.value = 30

	await ClockCycles(dut.clk, 20)

	# The following assersion is just an example of how to check the output values.
	# Change it to match the actual expected output of your module:
	# assert dut.uo_out.value == 50

	# Keep testing the module by changing the input values, waiting for
	# one or more clock cycles, and asserting the expected output values.


@cocotb.test()
async def test_opcode(dut):
	dut._log.info("Start")

	# Set the clock period to 10 us (100 KHz)
	clock = Clock(dut.clk, 10, units="us")
	cocotb.start_soon(clock.start())

	with open("opcodes.json") as f:
		opcodes = json.load(f)

	for opcode in opcodes["unprefixed"]:
		details = opcodes["unprefixed"][opcode]
		num = int(opcode, 16)

		mnemonic = details["mnemonic"]
		operands = details["operands"]

		full_name = mnemonic
		memory = [num]
		for i, operand in enumerate(operands):
			if i != 0:
				full_name += ","
			full_name += f" {operand["name"]}"

			if "bytes" in operand:
				for j in range(operand["bytes"]):
					memory.append(0xAA + j)

		assert len(memory) == details["bytes"]

		memory_dump = ""
		for i, byte in enumerate(memory):
			if i != 0:
				memory_dump += " "
			memory_dump += f"0x{byte:02X}"

		dut._log.info("Reset")
		dut.rst_n.value = 0
		dut.bus_data_in.value = 0
		await ClockCycles(dut.clk, 5)
		dut.rst_n.value = 1

		dut._log.info(f"Testing instruction {full_name} ({memory_dump})")

		bla = 0
		while True:

			if dut.bus_read:
				print("reading from", dut.bus_address_out.value)
				dut.bus_data_in.value = 0
				dut.bus_done.value = 1
			elif dut.bus_write:
				# TODO what to do???
				print("writing to", dut.bus_address_out.value, dut.bus_data_out.value)
				pass

			await ClockCycles(dut.clk, 1)
			bla += 1

			if bla > 10:
				break

		break