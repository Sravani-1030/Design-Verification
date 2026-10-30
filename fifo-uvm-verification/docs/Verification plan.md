# Verification Plan — Synchronous FIFO

**DUT:** `sync_fifo` (parameterizable, default WIDTH=8, DEPTH=8)
**Verification engineer:** Sravani Gajula
**Methodology:** UVM (SystemVerilog)

---

## 1. Purpose
Prove the synchronous FIFO behaves correctly under all legal and illegal
conditions, and find any bugs *before* the design would be manufactured.

## 2. DUT behavior being verified (the spec)
- **Write:** on a rising clock, if `wr_en=1` and `full=0`, `din` is stored.
- **Read:** on a rising clock, if `rd_en=1` and `empty=0`, the oldest value appears on `dout`.
- **FIFO ordering:** data comes out in the exact order it went in.
- **full:** asserts when DEPTH items are stored; writes while full are ignored.
- **empty:** asserts when 0 items are stored; reads while empty are ignored.
- **reset:** synchronous, active-high; clears pointers → FIFO becomes empty.

## 3. Features to verify (the checklist)
| # | Feature | How we'll check it |
|---|---------|--------------------|
| F1 | Basic write then read returns same data | scoreboard compares out vs a reference queue |
| F2 | FIFO ordering preserved | reference queue enforces order automatically |
| F3 | `full` asserts at DEPTH items | monitor samples `full`; coverage hits the full case |
| F4 | `empty` asserts at 0 items | monitor samples `empty`; coverage hits the empty case |
| F5 | Write while full is ignored (no data loss/corruption) | scoreboard must not gain an entry |
| F6 | Read while empty is ignored (no garbage accepted) | scoreboard must not lose/invent an entry |
| F7 | Reset returns FIFO to empty | directed reset test |
| F8 | Simultaneous read+write holds count steady | mixed random stimulus |

## 4. Corner cases / bugs to hunt 🐛
- Off-by-one on `full`/`empty` (asserts one entry too early or too late)
- Writing when full corrupts data or silently overwrites
- Reading when empty returns stale/garbage data
- Pointer wrap-around error (after DEPTH writes, indices must wrap cleanly)
- Order scrambled under back-to-back read+write

## 5. Stimulus strategy
- **Constrained-random**: random `wr_en`/`rd_en`/`din` sequences to explore mixes.
- **Directed**: deliberately fill to full, drain to empty, reset mid-stream.

## 6. Checking strategy
- **Scoreboard with a reference model** = a SystemVerilog **queue** (`din` pushed on
  accepted writes, popped and compared on accepted reads). The queue IS the golden FIFO.

## 7. Coverage goals
- Cover `full=1` and `empty=1` both reached.
- Cover write-while-full and read-while-empty attempts.
- Cover simultaneous read+write.
- Cover FIFO occupancy across its range (0 … DEPTH).

## 8. Pass/fail criteria
- **Pass:** every read value matches the reference queue; flags match expected occupancy;
  all coverage goals hit.
- **Fail:** any mismatch, or an illegal operation changes state when it shouldn't.

## 9. Status
- [x] Spec understood
- [x] DUT received
- [ ] Testbench built
- [ ] Scoreboard + reference model
- [ ] Coverage + assertions
- [ ] Bugs documented
- [ ] Write-up complete
