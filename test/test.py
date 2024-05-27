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

	pass_count = 0
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

		dut.rst_n.value = 0
		dut.bus_data_in.value = 0
		dut.bus_done.value = 0
		await ClockCycles(dut.clk, 5)
		dut.rst_n.value = 1

		register_A_start = 0x12
		register_B_start = 0x34

		dut.cpu_inst.register_A.value = register_A_start
		dut.cpu_inst.register_B.value = register_B_start

		bla = 0
		while True:

			if dut.bus_read.value.integer == 1:
				# print("reading from", dut.bus_address_out.value.integer)

				if dut.bus_address_out.value.integer < len(memory):
					dut.bus_data_in.value = memory[dut.bus_address_out.value.integer]
				else:
					dut.bus_data_in.value = 0

					# count this as finishing the test
					# TODO: is that dumb??
					break

				dut.bus_done.value = 1
			elif dut.bus_write.value.integer == 1:
				# TODO what to do???
				print("writing to", dut.bus_address_out.value, dut.bus_data_out.value)
				pass
			else:
				dut.bus_done.value = 0

			await ClockCycles(dut.clk, 1)
			bla += 1

			if bla > 20:
				dut._log.info(f"Testing instruction {full_name} ({memory_dump}): timeout")
				assert False

		passed = False

		# now, check the state of the CPU
		if mnemonic == "NOP":
			# nothing to really check
			passed = True
		elif mnemonic == "LD":
			# check if the value was loaded correctly

			loaded_value = 1
			expected_value = 2

			if operands[0]["name"] == "A":
				loaded_value = dut.cpu_inst.register_A.value.integer
			elif operands[0]["name"] == "B":
				loaded_value = dut.cpu_inst.register_B.value.integer

			if operands[1]["name"] == "A":
				expected_value = dut.cpu_inst.register_A.value.integer
			elif operands[1]["name"] == "B":
				expected_value = dut.cpu_inst.register_B.value.integer
			elif operands[1]["name"] == "n8":
				expected_value = memory[1]

			passed = loaded_value == expected_value
		elif mnemonic == "INC":
			# TODO: flags test
			if operands[0]["name"] == "A":
				passed = dut.cpu_inst.register_A.value.integer == register_A_start + 1
			elif operands[0]["name"] == "B":
				passed = dut.cpu_inst.register_B.value.integer == register_B_start + 1

		if passed:
			dut._log.info(f"Testing instruction {full_name} ({memory_dump}): pass")
			pass_count += 1
		else:
			dut._log.info(f"Testing instruction {full_name} ({memory_dump}): fail")

		# break
	dut._log.info(f"Passed {pass_count}/{len(opcodes["unprefixed"])} instructions")