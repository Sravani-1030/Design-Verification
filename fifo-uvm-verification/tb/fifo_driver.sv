//======================================================================
//  fifo_driver.sv — the "waiter": drives stimulus onto the DUT pins
//======================================================================
//  A uvm_COMPONENT — so: component utils, name+parent constructor.
//  run_phase is a TASK (consumes time: it waits on clock edges).
//======================================================================

class fifo_driver extends uvm_driver #(fifo_transaction);

    virtual fifo_if vif;                       // handle to the DUT pins

    `uvm_component_utils(fifo_driver)          // factory register (COMPONENT)

    function new(string name, uvm_component parent);
        super.new(name, parent);               // name + parent
    endfunction

    // Pick up the virtual interface that the top module dropped off.
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);  // ask sequencer for a transaction
            drive(req);                        // put it on the pins
            seq_item_port.item_done();         // tell sequencer "done"
        end
    endtask

    // One transaction = one clock cycle of stimulus.
    task drive(fifo_transaction t);
        @(posedge vif.clk);                    // sync to the clock edge
        vif.wr_en <= t.wr_en;
        vif.rd_en <= t.rd_en;
        vif.din   <= t.din;
    endtask

endclass
