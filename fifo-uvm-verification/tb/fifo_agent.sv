//======================================================================
//  fifo_agent.sv — bundles sequencer + driver + monitor
//======================================================================
//  build_phase CREATES the three children; connect_phase WIRES the
//  driver to the sequencer (the handshake cable).
//======================================================================

class fifo_agent extends uvm_agent;

    fifo_driver                        drv;
    fifo_monitor                       mon;
    uvm_sequencer #(fifo_transaction)  seqr;      // built-in sequencer

    `uvm_component_utils(fifo_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv  = fifo_driver::type_id::create("drv", this);
        mon  = fifo_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer#(fifo_transaction)::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // driver <-> sequencer handshake cable
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass
