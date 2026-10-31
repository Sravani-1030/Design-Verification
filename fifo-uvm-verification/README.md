# Synchronous FIFO — UVM Verification Project

A complete, self-checking **UVM testbench** verifying a parameterizable synchronous FIFO,
built in SystemVerilog. Demonstrates a full verification environment: constrained-random
stimulus, a reference-model scoreboard, functional coverage, and SystemVerilog assertions.

---

## Overview

This project verifies a synchronous FIFO (First-In-First-Out buffer) — a fundamental building
block found in nearly every digital design. The goal is to prove the design behaves correctly
under all legal and illegal conditions, using the industry-standard **Universal Verification
Methodology (UVM)**.

**Verification approach — three independent layers of checking:**
- **Scoreboard** (correctness) — a golden reference model compares every DUT output against expected.
- **Functional coverage** (thoroughness) — covergroups measure which scenarios were actually exercised.
- **Assertions / SVA** (structural rules) — standing properties checked every clock cycle.

---

## The Design Under Test (DUT)

A parameterizable synchronous FIFO (`rtl/sync_fifo.sv`):

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `WIDTH` | 8 | data width in bits |
| `DEPTH` | 8 | number of entries |

| Port | Dir | Description |
|------|-----|-------------|
| `clk` | in | clock |
| `rst` | in | synchronous reset (active high) |
| `wr_en` | in | write enable |
| `rd_en` | in | read enable |
| `din` | in | data in |
| `dout` | out | data out (oldest entry) |
| `full` | out | asserts when FIFO is full |
| `empty` | out | asserts when FIFO is empty |

**Behavior verified:** FIFO ordering, write-when-not-full, read-when-not-empty, correct full/empty
flags (including the pointer wrap-around trick), write-while-full ignored, read-while-empty ignored,
and reset behavior.

---

## Testbench Architecture

Standard UVM hierarchy:

```
                 fifo_test
                     |
                  fifo_env
                 /        \
          fifo_agent    fifo_scoreboard   + fifo_coverage
          /   |   \
    sequencer driver monitor
                        |
              (analysis port broadcast)
                        |
            scoreboard + coverage (both listen)
```

**Data flow (life of one transaction):**
```
sequence -> sequencer -> driver -> DUT -> monitor -> scoreboard (check) + coverage (measure)
```

| Component | Role |
|-----------|------|
| `fifo_transaction` | one unit of stimulus (`wr_en`, `rd_en`, `din`) + observed response |
| `fifo_sequence` | generates 200 constrained-random transactions |
| `fifo_driver` | drives transactions onto the DUT pins via a virtual interface |
| `fifo_monitor` | samples the pins, broadcasts observed transactions |
| `fifo_scoreboard` | golden reference (SystemVerilog queue); checks every read |
| `fifo_coverage` | covergroups measuring functional coverage |
| `fifo_agent` | bundles sequencer + driver + monitor |
| `fifo_env` | bundles agent + scoreboard + coverage |
| `fifo_test` | top-level test; starts the sequence |

---

## Verification Features

**Constrained-random stimulus** — `wr_en`/`rd_en`/`din` are randomized with weighted
distributions (`dist`) biased toward writes, so the FIFO reaches `full` and interesting mixes.

**Reference-model scoreboard** — a SystemVerilog queue mirrors correct FIFO behavior
(`push_back` on accepted writes, `pop_front` on accepted reads). Every DUT read is compared
against the queue. Handles the DUT's 1-cycle registered-output read latency.

**Functional coverage** — covergroups track:
- `full` reached (0 and 1)
- `empty` reached (0 and 1)
- writes and reads exercised
- **cross** of `wr_en` × `rd_en` (simultaneous read+write corner case)

**SystemVerilog Assertions** (in the interface):
- `full` and `empty` are never both high
- flags never go unknown (x/z) after reset
- reset forces the FIFO empty

---

## Repository Structure

```
.
├── README.md
├── rtl/
│   └── sync_fifo.sv          # the DUT
├── tb/
│   ├── fifo_if.sv            # interface (+ assertions)
│   ├── fifo_transaction.sv
│   ├── fifo_sequence.sv
│   ├── fifo_driver.sv
│   ├── fifo_monitor.sv
│   ├── fifo_scoreboard.sv
│   ├── fifo_coverage.sv
│   ├── fifo_agent.sv
│   ├── fifo_env.sv
│   ├── fifo_test.sv
│   ├── fifo_pkg.sv           # packages all classes
│   └── fifo_tb_top.sv        # top module (DUT + interface + run_test)
├── eda_playground/
│   ├── testbench.sv          # single-file version (all TB) for EDA Playground
│   └── design.sv             # single-file DUT for EDA Playground
└── docs/
    └── verification_plan.md  # the verification plan
```

---

## How to Run

Requires a SystemVerilog simulator with UVM 1.2 support.

**EDA Playground (free, browser):**
1. Paste `eda_playground/testbench.sv` into the left pane, `eda_playground/design.sv` into the right.
2. Languages & Libraries → **UVM 1.2**.
3. Tools & Simulators → a UVM-capable simulator (Riviera-Pro / VCS / Questa).
4. Run.

**Local simulator (example — Questa):**
```bash
vlog -sv +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv \
     rtl/sync_fifo.sv tb/fifo_if.sv tb/fifo_pkg.sv tb/fifo_tb_top.sv
vsim -c fifo_tb_top -do "run -all; quit"
```

**Expected output:**
```
UVM_INFO [SB]  Checks run: <N> | Errors: 0
UVM_INFO [SB]  *** TEST PASSED ***
UVM_INFO [COV] Functional coverage = <percent>%
```

---

## Results

Simulated on **Cadence Xcelium** (UVM 1.2), 200 constrained-random transactions:

```
[COV] Functional coverage = 100.00%
[SB]  Checks run: 94 | Errors: 0
[SB]  *** TEST PASSED ***
UVM_ERROR : 0   UVM_FATAL : 0
```

- **Correctness:** 94 scoreboard checks, 0 mismatches — the DUT matched the golden
  reference model on every read.
- **Coverage:** 100% functional coverage — all defined scenarios exercised (FIFO full,
  FIFO empty, writes, reads, and the simultaneous read+write cross).
- **Clean run:** zero UVM errors, zero fatals.

*(Assertions in `fifo_if.sv` are valid SVA; they require a simulator with an SVA license
to simulate and are commented out in the free-tier EDA Playground version.)*

---

## Skills Demonstrated

- UVM testbench architecture (agent, env, test, sequencer/driver/monitor, scoreboard)
- Constrained-random verification (`rand`, `constraint`, `dist`)
- Functional coverage (covergroups, coverpoints, bins, cross)
- SystemVerilog Assertions (concurrent properties, implication operators)
- Reference-model checking, virtual interfaces, `uvm_config_db`, the factory, UVM phases
- A written verification plan and documented methodology

---

## Author

**Sravani Gajula** — transitioning from QA/SDET into Design Verification.

*This project was built as a hands-on study of UVM-based functional verification.*
