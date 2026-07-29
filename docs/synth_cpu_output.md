# CPU Synthesis Summary

Tool: Yosys 0.67+post
Command: yosys -s scripts/synth_cpu.ys
Top module: cpu
Status: Synthesis completed successfully with no reported warnings or errors.

## Generated files

| File                  | Purpose                         |
|-----------------------|---------------------------------|
| build/cpu_synth.v     | Synthesized gate-level Verilog |
| build/cpu.blif        | Synthesized BLIF netlist       |

## Design hierarchy

The cpu top module contains one instance of each module below:

- alu
- control
- data_mem
- imm_gen
- instr_mem
- pc
- regfile

## Overall design statistics

| Metric                 | Count |
|------------------------|------:|
| Wires                  | 60,424 |
| Wire bits              | 78,477 |
| Public wires           | 635 |
| Public wire bits       | 18,688 |
| Ports                  | 54 |
| Port bits              | 680 |
| Memories               | 0 |
| Memory bits            | 0 |
| Processes              | 0 |
| Cells                   | 77,469 |

## Cell count by module

The cell count column is local to each module. The inclusive count includes all
cells below that module in the hierarchy.

| Module    | Wires | Wire bits | Local cells | Inclusive cells |
|-----------|------:|----------:|------------:|----------------:|
| cpu       | 825 | 1,417 | 880 | 77,469 |
| data_mem  | 53,994 | 69,990 | 69,890 | 69,890 |
| regfile   | 3,854 | 4,982 | 4,868 | 4,868 |
| alu       | 1,268 | 1,364 | 1,295 | 1,295 |
| pc        | 333 | 395 | 359 | 359 |
| imm_gen   | 64 | 132 | 93 | 93 |
| control   | 83 | 101 | 84 | 84 |
| instr_mem | 3 | 96 | 0 | 0 |

## Overall cell distribution

| Cell type       | Count |
|-----------------|------:|
| $_AND_          | 27,469 |
| $_DFFE_PP_      | 17,376 |
| $_NAND_         | 14,941 |
| $_MUX_          | 8,524 |
| $_OR_           | 4,853 |
| $_ORNOT_        | 3,754 |
| $_ANDNOT_       | 187 |
| $_XNOR_         | 134 |
| $_XOR_          | 94 |
| $_NOR_          | 89 |
| $_SDFF_PP0_     | 30 |
| $_NOT_          | 16 |
| $_SDFFE_PP0P_   | 2 |
| Total           | 77,469 |

## Memory mapping results

| Source storage | Entries | Width | Flip-flop cells created | Read mux cells created |
|----------------|--------:|------:|-------------------------:|-----------------------:|
| Data memory    | 512 | 32 | 512 | 511 |
| Register file  | 32 | 32 | 32 | 62 |
| Instruction memory | 512 | 30 | 512 | 511 |

Yosys mapped the inferred memories into flip-flops and multiplexers instead of
retaining memory cells. This explains why the final design reports zero memories
and why data_mem accounts for most of the generic logic cells. The instruction
memory has no remaining cells in the final hierarchy because its initialized
contents were optimized into the surrounding logic during synthesis.

## Interpretation limits

These are generic Yosys synthesis statistics. They do not provide target-specific
FPGA resource usage, standard-cell area, maximum clock frequency, power, or timing
closure results. A technology-mapped synthesis and timing flow is required for
those measurements.

## Runtime

| Metric          | Value     |
|-----------------|-----------|
| Wall-clock time | 9.02 s    |
| User CPU time   | 4.82 s    |
| System CPU time | 0.16 s    |
| Peak memory     | 411.22 MB |
