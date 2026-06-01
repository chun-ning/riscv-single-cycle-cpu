# RISC-V Single-Cycle CPU

This project implements a simple 32-bit single-cycle RISC-V CPU in Verilog. The goal is to build and test a small RV32I-style processor with a modular datapath and control unit.

## Project Overview

The CPU is designed as a single-cycle processor, meaning each instruction completes in one clock cycle. The design includes the main components of a basic processor:

- Program counter
- Instruction memory
- Register file
- Immediate generator
- ALU
- Control unit
- Data memory
- Writeback logic

## Supported Instructions

This project currently supports a small subset of RISC-V instructions, including:

- Arithmetic: `add`, `sub`, `addi`
- Logic: `and`, `or`, `xor`
- Memory: `lw`, `sw`
- Branches: `beq`, `bne`, `blt`
- Jumps: `jal`
- Upper immediate: `lui`

More instructions may be added later.

## Tools

This project uses:

- Verilog
- Icarus Verilog for simulation
- GTKWave for waveform viewing
- Git and GitHub for version control

## How to Run

Compile and run a testbench using Icarus Verilog:

```bash
iverilog -o cpu_test tb/tb_cpu.v rtl/*.v
vvp cpu_test