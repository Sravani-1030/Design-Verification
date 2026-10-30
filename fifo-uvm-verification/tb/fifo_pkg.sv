//======================================================================
//  fifo_pkg.sv — packages all the UVM classes together
//======================================================================
//  A package groups related classes so they compile and import as one
//  unit. The top module does `import fifo_pkg::*;` to get them all.
//  Order matters: a class must be included AFTER anything it uses.
//======================================================================

package fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "fifo_transaction.sv"
    `include "fifo_sequence.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_coverage.sv"
    `include "fifo_agent.sv"
    `include "fifo_env.sv"
    `include "fifo_test.sv"
endpackage
