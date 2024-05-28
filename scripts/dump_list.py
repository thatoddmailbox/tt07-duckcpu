import json

with open("opcodes.json") as f:
	opcodes = json.load(f)

for opcode in opcodes["unprefixed"]:
	details = opcodes["unprefixed"][opcode]
	num = int(opcode, 16)

	mnemonic = details["mnemonic"]

	full_name = mnemonic
	i = 0
	for operand in details["operands"]:
		if i != 0:
			full_name += ","
		wrapped_name = operand["name"]
		if not operand["immediate"]:
			wrapped_name = f"[{wrapped_name}]"
		full_name += f" {wrapped_name}"
		i += 1

	print("(current_insn == 8'h{:02X}) ? ".format(num), end="")
	print(f"\"{full_name}\" :")