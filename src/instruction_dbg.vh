wire [127:0] current_insn_name;

assign current_insn_name = (current_insn == 8'h00) ? "NOP" :
							(current_insn == 8'h01) ? "LD BC, n16" :
							(current_insn == 8'h02) ? "LD BC, A" :
							(current_insn == 8'h03) ? "INC BC" :
							(current_insn == 8'h04) ? "INC B" :
							(current_insn == 8'h05) ? "DEC B" :
							(current_insn == 8'h06) ? "LD B, n8" :
							(current_insn == 8'h07) ? "RLCA" :
							(current_insn == 8'h08) ? "LD a16, SP" :
							(current_insn == 8'h09) ? "ADD HL, BC" :
							(current_insn == 8'h0A) ? "LD A, BC" :
							(current_insn == 8'h0B) ? "DEC BC" :
							(current_insn == 8'h0C) ? "INC C" :
							(current_insn == 8'h0D) ? "DEC C" :
							(current_insn == 8'h0E) ? "LD C, n8" :
							(current_insn == 8'h0F) ? "RRCA" :
							(current_insn == 8'h10) ? "STOP n8" :
							(current_insn == 8'h11) ? "LD DE, n16" :
							(current_insn == 8'h12) ? "LD DE, A" :
							(current_insn == 8'h13) ? "INC DE" :
							(current_insn == 8'h14) ? "INC D" :
							(current_insn == 8'h15) ? "DEC D" :
							(current_insn == 8'h16) ? "LD D, n8" :
							(current_insn == 8'h17) ? "RLA" :
							(current_insn == 8'h18) ? "JR e8" :
							(current_insn == 8'h19) ? "ADD HL, DE" :
							(current_insn == 8'h1A) ? "LD A, DE" :
							(current_insn == 8'h1B) ? "DEC DE" :
							(current_insn == 8'h1C) ? "INC E" :
							(current_insn == 8'h1D) ? "DEC E" :
							(current_insn == 8'h1E) ? "LD E, n8" :
							(current_insn == 8'h1F) ? "RRA" :
							(current_insn == 8'h20) ? "JR NZ, e8" :
							(current_insn == 8'h21) ? "LD HL, n16" :
							(current_insn == 8'h22) ? "LD HL, A" :
							(current_insn == 8'h23) ? "INC HL" :
							(current_insn == 8'h24) ? "INC H" :
							(current_insn == 8'h25) ? "DEC H" :
							(current_insn == 8'h26) ? "LD H, n8" :
							(current_insn == 8'h27) ? "DAA" :
							(current_insn == 8'h28) ? "JR Z, e8" :
							(current_insn == 8'h29) ? "ADD HL, HL" :
							(current_insn == 8'h2A) ? "LD A, HL" :
							(current_insn == 8'h2B) ? "DEC HL" :
							(current_insn == 8'h2C) ? "INC L" :
							(current_insn == 8'h2D) ? "DEC L" :
							(current_insn == 8'h2E) ? "LD L, n8" :
							(current_insn == 8'h2F) ? "CPL" :
							(current_insn == 8'h30) ? "JR NC, e8" :
							(current_insn == 8'h31) ? "LD SP, n16" :
							(current_insn == 8'h32) ? "LD HL, A" :
							(current_insn == 8'h33) ? "INC SP" :
							(current_insn == 8'h34) ? "INC HL" :
							(current_insn == 8'h35) ? "DEC HL" :
							(current_insn == 8'h36) ? "LD HL, n8" :
							(current_insn == 8'h37) ? "SCF" :
							(current_insn == 8'h38) ? "JR C, e8" :
							(current_insn == 8'h39) ? "ADD HL, SP" :
							(current_insn == 8'h3A) ? "LD A, HL" :
							(current_insn == 8'h3B) ? "DEC SP" :
							(current_insn == 8'h3C) ? "INC A" :
							(current_insn == 8'h3D) ? "DEC A" :
							(current_insn == 8'h3E) ? "LD A, n8" :
							(current_insn == 8'h3F) ? "CCF" :
							(current_insn == 8'h40) ? "LD B, B" :
							(current_insn == 8'h41) ? "LD B, C" :
							(current_insn == 8'h42) ? "LD B, D" :
							(current_insn == 8'h43) ? "LD B, E" :
							(current_insn == 8'h44) ? "LD B, H" :
							(current_insn == 8'h45) ? "LD B, L" :
							(current_insn == 8'h46) ? "LD B, HL" :
							(current_insn == 8'h47) ? "LD B, A" :
							(current_insn == 8'h48) ? "LD C, B" :
							(current_insn == 8'h49) ? "LD C, C" :
							(current_insn == 8'h4A) ? "LD C, D" :
							(current_insn == 8'h4B) ? "LD C, E" :
							(current_insn == 8'h4C) ? "LD C, H" :
							(current_insn == 8'h4D) ? "LD C, L" :
							(current_insn == 8'h4E) ? "LD C, HL" :
							(current_insn == 8'h4F) ? "LD C, A" :
							(current_insn == 8'h50) ? "LD D, B" :
							(current_insn == 8'h51) ? "LD D, C" :
							(current_insn == 8'h52) ? "LD D, D" :
							(current_insn == 8'h53) ? "LD D, E" :
							(current_insn == 8'h54) ? "LD D, H" :
							(current_insn == 8'h55) ? "LD D, L" :
							(current_insn == 8'h56) ? "LD D, HL" :
							(current_insn == 8'h57) ? "LD D, A" :
							(current_insn == 8'h58) ? "LD E, B" :
							(current_insn == 8'h59) ? "LD E, C" :
							(current_insn == 8'h5A) ? "LD E, D" :
							(current_insn == 8'h5B) ? "LD E, E" :
							(current_insn == 8'h5C) ? "LD E, H" :
							(current_insn == 8'h5D) ? "LD E, L" :
							(current_insn == 8'h5E) ? "LD E, HL" :
							(current_insn == 8'h5F) ? "LD E, A" :
							(current_insn == 8'h60) ? "LD H, B" :
							(current_insn == 8'h61) ? "LD H, C" :
							(current_insn == 8'h62) ? "LD H, D" :
							(current_insn == 8'h63) ? "LD H, E" :
							(current_insn == 8'h64) ? "LD H, H" :
							(current_insn == 8'h65) ? "LD H, L" :
							(current_insn == 8'h66) ? "LD H, HL" :
							(current_insn == 8'h67) ? "LD H, A" :
							(current_insn == 8'h68) ? "LD L, B" :
							(current_insn == 8'h69) ? "LD L, C" :
							(current_insn == 8'h6A) ? "LD L, D" :
							(current_insn == 8'h6B) ? "LD L, E" :
							(current_insn == 8'h6C) ? "LD L, H" :
							(current_insn == 8'h6D) ? "LD L, L" :
							(current_insn == 8'h6E) ? "LD L, HL" :
							(current_insn == 8'h6F) ? "LD L, A" :
							(current_insn == 8'h70) ? "LD HL, B" :
							(current_insn == 8'h71) ? "LD HL, C" :
							(current_insn == 8'h72) ? "LD HL, D" :
							(current_insn == 8'h73) ? "LD HL, E" :
							(current_insn == 8'h74) ? "LD HL, H" :
							(current_insn == 8'h75) ? "LD HL, L" :
							(current_insn == 8'h76) ? "HALT" :
							(current_insn == 8'h77) ? "LD HL, A" :
							(current_insn == 8'h78) ? "LD A, B" :
							(current_insn == 8'h79) ? "LD A, C" :
							(current_insn == 8'h7A) ? "LD A, D" :
							(current_insn == 8'h7B) ? "LD A, E" :
							(current_insn == 8'h7C) ? "LD A, H" :
							(current_insn == 8'h7D) ? "LD A, L" :
							(current_insn == 8'h7E) ? "LD A, HL" :
							(current_insn == 8'h7F) ? "LD A, A" :
							(current_insn == 8'h80) ? "ADD A, B" :
							(current_insn == 8'h81) ? "ADD A, C" :
							(current_insn == 8'h82) ? "ADD A, D" :
							(current_insn == 8'h83) ? "ADD A, E" :
							(current_insn == 8'h84) ? "ADD A, H" :
							(current_insn == 8'h85) ? "ADD A, L" :
							(current_insn == 8'h86) ? "ADD A, HL" :
							(current_insn == 8'h87) ? "ADD A, A" :
							(current_insn == 8'h88) ? "ADC A, B" :
							(current_insn == 8'h89) ? "ADC A, C" :
							(current_insn == 8'h8A) ? "ADC A, D" :
							(current_insn == 8'h8B) ? "ADC A, E" :
							(current_insn == 8'h8C) ? "ADC A, H" :
							(current_insn == 8'h8D) ? "ADC A, L" :
							(current_insn == 8'h8E) ? "ADC A, HL" :
							(current_insn == 8'h8F) ? "ADC A, A" :
							(current_insn == 8'h90) ? "SUB A, B" :
							(current_insn == 8'h91) ? "SUB A, C" :
							(current_insn == 8'h92) ? "SUB A, D" :
							(current_insn == 8'h93) ? "SUB A, E" :
							(current_insn == 8'h94) ? "SUB A, H" :
							(current_insn == 8'h95) ? "SUB A, L" :
							(current_insn == 8'h96) ? "SUB A, HL" :
							(current_insn == 8'h97) ? "SUB A, A" :
							(current_insn == 8'h98) ? "SBC A, B" :
							(current_insn == 8'h99) ? "SBC A, C" :
							(current_insn == 8'h9A) ? "SBC A, D" :
							(current_insn == 8'h9B) ? "SBC A, E" :
							(current_insn == 8'h9C) ? "SBC A, H" :
							(current_insn == 8'h9D) ? "SBC A, L" :
							(current_insn == 8'h9E) ? "SBC A, HL" :
							(current_insn == 8'h9F) ? "SBC A, A" :
							(current_insn == 8'hA0) ? "AND A, B" :
							(current_insn == 8'hA1) ? "AND A, C" :
							(current_insn == 8'hA2) ? "AND A, D" :
							(current_insn == 8'hA3) ? "AND A, E" :
							(current_insn == 8'hA4) ? "AND A, H" :
							(current_insn == 8'hA5) ? "AND A, L" :
							(current_insn == 8'hA6) ? "AND A, HL" :
							(current_insn == 8'hA7) ? "AND A, A" :
							(current_insn == 8'hA8) ? "XOR A, B" :
							(current_insn == 8'hA9) ? "XOR A, C" :
							(current_insn == 8'hAA) ? "XOR A, D" :
							(current_insn == 8'hAB) ? "XOR A, E" :
							(current_insn == 8'hAC) ? "XOR A, H" :
							(current_insn == 8'hAD) ? "XOR A, L" :
							(current_insn == 8'hAE) ? "XOR A, HL" :
							(current_insn == 8'hAF) ? "XOR A, A" :
							(current_insn == 8'hB0) ? "OR A, B" :
							(current_insn == 8'hB1) ? "OR A, C" :
							(current_insn == 8'hB2) ? "OR A, D" :
							(current_insn == 8'hB3) ? "OR A, E" :
							(current_insn == 8'hB4) ? "OR A, H" :
							(current_insn == 8'hB5) ? "OR A, L" :
							(current_insn == 8'hB6) ? "OR A, HL" :
							(current_insn == 8'hB7) ? "OR A, A" :
							(current_insn == 8'hB8) ? "CP A, B" :
							(current_insn == 8'hB9) ? "CP A, C" :
							(current_insn == 8'hBA) ? "CP A, D" :
							(current_insn == 8'hBB) ? "CP A, E" :
							(current_insn == 8'hBC) ? "CP A, H" :
							(current_insn == 8'hBD) ? "CP A, L" :
							(current_insn == 8'hBE) ? "CP A, HL" :
							(current_insn == 8'hBF) ? "CP A, A" :
							(current_insn == 8'hC0) ? "RET NZ" :
							(current_insn == 8'hC1) ? "POP BC" :
							(current_insn == 8'hC2) ? "JP NZ, a16" :
							(current_insn == 8'hC3) ? "JP a16" :
							(current_insn == 8'hC4) ? "CALL NZ, a16" :
							(current_insn == 8'hC5) ? "PUSH BC" :
							(current_insn == 8'hC6) ? "ADD A, n8" :
							(current_insn == 8'hC7) ? "RST $00" :
							(current_insn == 8'hC8) ? "RET Z" :
							(current_insn == 8'hC9) ? "RET" :
							(current_insn == 8'hCA) ? "JP Z, a16" :
							(current_insn == 8'hCB) ? "PREFIX" :
							(current_insn == 8'hCC) ? "CALL Z, a16" :
							(current_insn == 8'hCD) ? "CALL a16" :
							(current_insn == 8'hCE) ? "ADC A, n8" :
							(current_insn == 8'hCF) ? "RST $08" :
							(current_insn == 8'hD0) ? "RET NC" :
							(current_insn == 8'hD1) ? "POP DE" :
							(current_insn == 8'hD2) ? "JP NC, a16" :
							(current_insn == 8'hD3) ? "ILLEGAL_D3" :
							(current_insn == 8'hD4) ? "CALL NC, a16" :
							(current_insn == 8'hD5) ? "PUSH DE" :
							(current_insn == 8'hD6) ? "SUB A, n8" :
							(current_insn == 8'hD7) ? "RST $10" :
							(current_insn == 8'hD8) ? "RET C" :
							(current_insn == 8'hD9) ? "RETI" :
							(current_insn == 8'hDA) ? "JP C, a16" :
							(current_insn == 8'hDB) ? "ILLEGAL_DB" :
							(current_insn == 8'hDC) ? "CALL C, a16" :
							(current_insn == 8'hDD) ? "ILLEGAL_DD" :
							(current_insn == 8'hDE) ? "SBC A, n8" :
							(current_insn == 8'hDF) ? "RST $18" :
							(current_insn == 8'hE0) ? "LDH a8, A" :
							(current_insn == 8'hE1) ? "POP HL" :
							(current_insn == 8'hE2) ? "LD C, A" :
							(current_insn == 8'hE3) ? "ILLEGAL_E3" :
							(current_insn == 8'hE4) ? "ILLEGAL_E4" :
							(current_insn == 8'hE5) ? "PUSH HL" :
							(current_insn == 8'hE6) ? "AND A, n8" :
							(current_insn == 8'hE7) ? "RST $20" :
							(current_insn == 8'hE8) ? "ADD SP, e8" :
							(current_insn == 8'hE9) ? "JP HL" :
							(current_insn == 8'hEA) ? "LD a16, A" :
							(current_insn == 8'hEB) ? "ILLEGAL_EB" :
							(current_insn == 8'hEC) ? "ILLEGAL_EC" :
							(current_insn == 8'hED) ? "ILLEGAL_ED" :
							(current_insn == 8'hEE) ? "XOR A, n8" :
							(current_insn == 8'hEF) ? "RST $28" :
							(current_insn == 8'hF0) ? "LDH A, a8" :
							(current_insn == 8'hF1) ? "POP AF" :
							(current_insn == 8'hF2) ? "LD A, C" :
							(current_insn == 8'hF3) ? "DI" :
							(current_insn == 8'hF4) ? "ILLEGAL_F4" :
							(current_insn == 8'hF5) ? "PUSH AF" :
							(current_insn == 8'hF6) ? "OR A, n8" :
							(current_insn == 8'hF7) ? "RST $30" :
							(current_insn == 8'hF8) ? "LD HL, SP, e8" :
							(current_insn == 8'hF9) ? "LD SP, HL" :
							(current_insn == 8'hFA) ? "LD A, a16" :
							(current_insn == 8'hFB) ? "EI" :
							(current_insn == 8'hFC) ? "ILLEGAL_FC" :
							(current_insn == 8'hFD) ? "ILLEGAL_FD" :
							(current_insn == 8'hFE) ? "CP A, n8" :
							(current_insn == 8'hFF) ? "RST $38" : "unknown";