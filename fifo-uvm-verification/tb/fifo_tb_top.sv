//======================================================================
//  fifo_tb_top.sv — the top module: where HARDWARE meets UVM
//======================================================================
//  A plain SystemVerilog module (NOT a UVM class) — the real top of the
//  simulation. It:
//    1. generates the clock
//    2. instantiates the interface and the DUT, wires them together
//    3. SETs the virtual interface into config_db
//    4. launches UVM with run_test()
//======================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import fifo_pkg::*;

module fifo_tb_top;

    // ---- 1. clock ----
    logic clk = 0;
    always #5 clk = ~clk;                 // 10ns period

    // ---- 2. interface + DUT, wired together ----
    fifo_if intf(clk);

    sync_fifo #(.WIDTH(8), .DEPTH(8)) dut (
        .clk   (intf.clk),
        .rst   (intf.rst),
        .wr_en (intf.wr_en),
        .rd_en (intf.rd_en),
        .din   (intf.din),
        .dout  (intf.dout),
        .full  (intf.full),
        .empty (intf.empty)
    );

    // ---- reset at the start ----
    initial begin
        intf.rst   = 1;
        intf.wr_en = 0;
        intf.rd_en = 0;
        intf.din   = 0;
        repeat (2) @(posedge clk);        // hold reset for 2 cycles
        intf.rst = 0;                     // release reset
    end

    // ---- 3 & 4. hand the vif to UVM, then start the test ----
    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", intf);  // SET (drop off)
        run_test("fifo_test");            // launch UVM, run fifo_test
    end

    // ---- optional: dump waveforms for viewing ----
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb_top);
    end

endmodule
