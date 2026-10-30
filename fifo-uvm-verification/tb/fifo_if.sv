//======================================================================
//  fifo_if.sv — the interface: the bundle of DUT pins
//======================================================================
//  This is the physical "connector" between the UVM testbench and the
//  FIFO. The driver/monitor reach these pins through a virtual handle
//  (vif) delivered by uvm_config_db.
//
//  clk comes in from the top module (the whole TB shares one clock).
//======================================================================

interface fifo_if(input logic clk);
    logic        rst;      // reset
    logic        wr_en;    // write enable  (driver sets)
    logic        rd_en;    // read enable   (driver sets)
    logic [7:0]  din;      // data in       (driver sets)
    logic [7:0]  dout;     // data out      (monitor samples)
    logic        full;     // full flag     (monitor samples)
    logic        empty;    // empty flag    (monitor samples)

    //==================================================================
    //  ASSERTIONS (SVA) — standing rules checked every clock cycle
    //==================================================================

    // 1) full and empty can NEVER both be true at the same time
    a_not_full_and_empty: assert property (@(posedge clk)
        !(full && empty)
    ) else $error("ASSERT: full and empty both high!");

    // 2) the flags must never be unknown (x/z) after reset is released
    a_flags_known: assert property (@(posedge clk) disable iff (rst)
        !$isunknown({full, empty})
    ) else $error("ASSERT: full/empty went unknown!");

    // 3) after reset is applied, the FIFO must be empty the next cycle
    a_reset_makes_empty: assert property (@(posedge clk)
        rst |=> empty
    ) else $error("ASSERT: FIFO not empty after reset!");

endinterface
