//======================================================================
//  fifo_test.sv — the top of the tree: creates env, runs the sequence
//======================================================================
//  run_phase is a TASK (seq.start blocks / consumes time).
//  raise/drop objection keeps the sim alive while the sequence runs.
//======================================================================

class fifo_test extends uvm_test;

    fifo_env env;

    `uvm_component_utils(fifo_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_sequence seq;
        phase.raise_objection(this);                 // "don't end yet"
        seq = fifo_sequence::type_id::create("seq");
        seq.start(env.agt.seqr);                     // run sequence ON the sequencer
        phase.drop_objection(this);                  // "done, sim can end"
    endtask

endclass
