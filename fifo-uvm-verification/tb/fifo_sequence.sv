//======================================================================
//  fifo_sequence.sv — the "recipe": generates FIFO transactions
//======================================================================
//  A uvm_OBJECT (extends uvm_sequence) — object utils, name-only ctor.
//  body() makes N random transactions and hands each to the driver
//  via the start_item / finish_item handshake.
//======================================================================

class fifo_sequence extends uvm_sequence #(fifo_transaction);

    `uvm_object_utils(fifo_sequence)

    int num_txns = 200;        // how many transactions to generate

    function new(string name = "fifo_sequence");
        super.new(name);
    endfunction

    task body();
        repeat (num_txns) begin
            req = fifo_transaction::type_id::create("req");  // build via factory
            start_item(req);                                 // "driver, ready one"
            if (!req.randomize())                            // randomize + check!
                `uvm_error("SEQ", "randomize failed")
            finish_item(req);                                // "take it"
        end
    endtask

endclass
