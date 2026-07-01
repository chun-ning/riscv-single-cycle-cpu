# Instruction Subset
## Supported Instructions
- 4'h0:  add
- 4'h1:  sub
- 4'h2:  and
- 4'h3:  or
- 4'h4:  xor
- 4'h5:  sll
- 4'h6:  srl
- 4'h7:  sra
- 4'h8:  slt
- 4'h9:  sltu
- default

---
## LUI (U-type)

**Encoding**

| 31 ................................... 12 | 11 ......... 7 | 6 ............. 0 |
|:---:|:---:|:---:|
| imm[31:12] | rd | `0110111` |

**Format:** `lui rd, imm`

**Description:** Places the 20-bit immediate into bits 31:12 of `rd`, zero-filling the low 12 bits. Your RTL sign-extends it (`{20{instr[31]}, instr[31:12]}`), but per spec `lui` does not sign-extend — the low 12 bits are just `0`. *(Worth double-checking against your intended semantics.)*

---

## OP_IMM — e.g. `addi`, `slti`, `xori` (I-type)

**Encoding**

| 31 ......... 20 | 19 ..... 15 | 14 12 | 11 ...... 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|
| imm[11:0] | rs1 | funct3 | rd | `0010011` |

**Format:** `addi rd, rs1, imm`

**Description:** Sign-extends the 12-bit immediate and adds it to `rs1`, placing the result in `rd`. `funct3` distinguishes the specific op (`000`=addi, `010`=slti, `011`=sltiu, `100`=xori, `110`=ori, `111`=andi, `001`=slli, `101`=srli/srai).

**Immediate extraction:** `imm = {20{instr[31]}, instr[31:20]}`

---

## LOAD — e.g. `lw`, `lb`, `lh` (I-type)

**Encoding**

| 31 ......... 20 | 19 ..... 15 | 14 12 | 11 ...... 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|
| imm[11:0] | rs1 | funct3 | rd | `0000011` |

**Format:** `lw rd, imm(rs1)`

**Description:** Loads a value from memory address `rs1 + sign_extend(imm)` into `rd`. `funct3` selects width/signedness (`000`=lb, `001`=lh, `010`=lw, `100`=lbu, `101`=lhu).

**Immediate extraction:** `imm = {20{instr[31]}, instr[31:20]}` (same as I-type above)

---

## STORE — e.g. `sw`, `sb`, `sh` (S-type)

**Encoding**

| 31 ....... 25 | 24 .... 20 | 19 .... 15 | 14 12 | 11 ....... 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | `0100011` |

**Format:** `sw rs2, imm(rs1)`

**Description:** Stores the value in `rs2` to memory address `rs1 + sign_extend(imm)`. The immediate is split across two fields since `rd`'s slot is used for `imm[4:0]` (rd isn't needed for a store).

**Immediate extraction:** `imm = {20{instr[31]}, instr[31:25], instr[11:7]}`

---

## BRANCH — e.g. `beq`, `bne`, `blt` (B-type)

**Encoding**

| 31 | 30 ..... 25 | 24 .. 20 | 19 .. 15 | 14 12 | 11 ....... 8 | 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | `1100011` |

**Format:** `beq rs1, rs2, imm`

**Description:** Compares `rs1` and `rs2` per `funct3` (`000`=beq, `001`=bne, `100`=blt, `101`=bge, `110`=bltu, `111`=bgeu); if true, branches to `PC + sign_extend(imm)`. Note the immediate is encoded out of order and **bit 0 is implicitly 0** (branches are always 2-byte aligned), so it represents an even offset only.

**Immediate extraction:** `imm = {20{instr[31]}, instr[7], instr[30:25], instr[11:8], 1'b0}`
*(your current code is missing the trailing `1'b0` and duplicates `instr[31]` where `imm[11]`/`instr[7]` should go — worth fixing)*

---

## JAL (J-type)

**Encoding**

| 31 | 30 ....... 21 | 20 | 19 ......... 12 | 11 ...... 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | `1101111` |

**Format:** `jal rd, imm`

**Description:** Jumps to `PC + sign_extend(imm)` and stores `PC+4` in `rd`. Like branch, bit 0 is implicitly 0. Note: `jal`'s correct opcode is `1101111`, not `1100111` as in your `localparam` (that value is currently a duplicate of `jalr`'s opcode).

**Immediate extraction:** `imm = {11{instr[31]}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}`

---

## JALR (I-type)

**Encoding**

| 31 ......... 20 | 19 ..... 15 | 14 12 | 11 ...... 7 | 6 ......... 0 |
|:---:|:---:|:---:|:---:|:---:|
| imm[11:0] | rs1 | `000` | rd | `1100111` |

**Format:** `jalr rd, rs1, imm`

**Description:** Jumps to `(rs1 + sign_extend(imm)) & ~1` and stores `PC+4` in `rd`.

**Immediate extraction:** `imm = {20{instr[31]}, instr[31:20]}`

---
