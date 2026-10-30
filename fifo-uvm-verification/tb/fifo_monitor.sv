//======================================================================
//  fifo_monitor.sv — the "camera": observes DUT pins, broadcasts them
//======================================================================
//  A uvm_COMPONENT. Watches the interface every clock and sends out a
//  transaction describing what happened, via an analysis port.
//======================================================================

class fifo_monitor extends uvm_monitor;

    virtual fifo_if vif;                                 // handle to DUT pins
    uvm_analysis_port #(fifo_transaction) ap;            // broadcast "out" pipe

    `uvm_component_utils(fifo_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);                            // build the port here
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);                          // every clock edge...
            if (!vif.rst) begin                          // (ignore reset cycles)
                fifo_transaction t = fifo_transaction::type_id::create("t");
                // capture what was applied + what the DUT showed
                t.wr_en = vif.wr_en;
                t.rd_en = vif.rd_en;
                t.din   = vif.din;
                t.dout  = vif.dout;
                t.full  = vif.full;
                t.empty = vif.empty;
                ap.write(t);                             // broadcast to scoreboard
            end
        end
    endtask

endclass
