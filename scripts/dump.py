import json

with open("opcodes.json") as f:
	opcodes = json.load(f)

for opcode in opcodes["unprefixed"]:
	details = opcodes["unprefixed"][opcode]
	num = int(opcode, 16)

	mnemonic = details["mnemonic"]

	x = (num & 0b11000000) >> 6
	y = (num & 0b00111000) >> 3
	z = (num & 0b00000111)

	print(f"{mnemonic}: {opcode} -> x = {x}, y = {y}, z = {z}")