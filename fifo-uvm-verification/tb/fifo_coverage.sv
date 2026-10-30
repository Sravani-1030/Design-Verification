//======================================================================
//  fifo_coverage.sv — functional coverage collector
//======================================================================
//  Listens to the monitor's broadcast (same stream as the scoreboard)
//  and records WHICH situations the random stimulus actually exercised.
//  At the end it reports a coverage percentage.
//======================================================================

class fifo_coverage extends uvm_component;

    `uvm_component_utils(fifo_coverage)

    // inbox: receives the same transactions the monitor broadcasts
    uvm_analysis_imp #(fifo_transaction, fifo_coverage) analysis_export;

    fifo_transaction tr;   // holds the current transaction for the covergroup to sample

    // ---- the covergroup: our testing checklist ----
    covergroup fifo_cg;

        // coverpoint 1: did we see the FIFO both NOT-full and full?
        cp_full: coverpoint tr.full {
            bins not_full = {0};
            bins is_full  = {1};
        }

        // coverpoint 2: did we see it both NOT-empty and empty?
        cp_empty: coverpoint tr.empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }

        // coverpoint 3: did we see writes and reads happen (and not)?
        cp_wr: coverpoint tr.wr_en { bins no_wr = {0}; bins wr = {1}; }
        cp_rd: coverpoint tr.rd_en { bins no_rd = {0}; bins rd = {1}; }

        // cross: did we ever see a simultaneous read AND write?
        cross_rw: cross cp_wr, cp_rd;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        fifo_cg = new();                    // covergroups are built with new()
    endfunction

    // called each time the monitor broadcasts a transaction
    function void write(fifo_transaction t);
        tr = t;                             // put it where the covergroup can see it
        fifo_cg.sample();                   // record this situation
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%", fifo_cg.get_coverage()),
                  UVM_LOW)
    endfunction

endclass
