//======================================================================
//  fifo_scoreboard.sv — the "judge": checks DUT output vs a golden model
//======================================================================
//  Golden model = a SystemVerilog queue that behaves like a perfect FIFO.
//  Receives observed transactions from the monitor via analysis_export.
//
//  KEY SUBTLETY: the DUT's 'dout' is registered, so read data appears
//  ONE CYCLE after rd_en. The scoreboard remembers the expected value
//  and checks it on the next transaction (a 1-deep pipeline).
//======================================================================

class fifo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fifo_scoreboard)

    // the monitor's analysis port connects here (the "inbox")
    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) analysis_export;

    bit [7:0] ref_q[$];          // the GOLDEN reference FIFO (a queue)

    // pipeline for the DUT's 1-cycle read latency
    bit       expect_valid;      // is there a pending read result to check?
    bit [7:0] expect_data;       // what we expect dout to be next cycle

    int num_checks;
    int num_errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    // Called automatically each time the monitor does ap.write(t)
    function void write(fifo_transaction t);

        // 1) Check the read we saw LAST cycle (dout is one cycle late)
        if (expect_valid) begin
            num_checks++;
            if (t.dout !== expect_data) begin
                num_errors++;
                `uvm_error("SB", $sformatf("READ MISMATCH: expected 0x%0h, got 0x%0h",
                                           expect_data, t.dout))
            end
            expect_valid = 0;
        end

        // 2) Model a WRITE — accepted only if NOT full (mirrors the DUT)
        if (t.wr_en && !t.full)
            ref_q.push_back(t.din);

        // 3) Model a READ — accepted only if NOT empty; expect this NEXT cycle
        if (t.rd_en && !t.empty) begin
            expect_data  = ref_q.pop_front();   // oldest value = what dout should show
            expect_valid = 1;
        end
    endfunction

    // End-of-test summary
    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("Checks run: %0d | Errors: %0d", num_checks, num_errors), UVM_LOW)
        if (num_errors == 0)
            `uvm_info("SB", "*** TEST PASSED ***", UVM_LOW)
        else
            `uvm_error("SB", "*** TEST FAILED ***")
    endfunction

endclass
