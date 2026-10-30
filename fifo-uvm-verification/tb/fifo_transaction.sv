//======================================================================
//  fifo_transaction.sv — one unit of FIFO stimulus + observed response
//======================================================================
//  A uvm_OBJECT (data that flows through the TB) — so: object utils,
//  name-only constructor, NO parent.
//======================================================================

class fifo_transaction extends uvm_sequence_item;

    // ---- STIMULUS: driven INTO the DUT (randomized) ----
    rand bit       wr_en;      // write this cycle?
    rand bit       rd_en;      // read this cycle?
    rand bit [7:0] din;        // data to write (if writing)

    // ---- RESPONSE: observed FROM the DUT (filled by the monitor) ----
    bit [7:0] dout;            // data the FIFO gave out
    bit       full;            // was it full?
    bit       empty;           // was it empty?

    `uvm_object_utils(fifo_transaction)      // factory register (OBJECT)

    function new(string name = "fifo_transaction");
        super.new(name);                     // name only — no parent
    endfunction

    // ---- CONSTRAINTS: keep the random stimulus useful ----
    // Bias toward activity so we don't waste cycles doing nothing.
    // 'dist' = weighted distribution (you learned this exists!).
    constraint c_write_bias { wr_en dist {1 := 70, 0 := 30}; }  // write ~70% of cycles
    constraint c_read_bias  { rd_en dist {1 := 50, 0 := 50}; }  // read  ~50% of cycles

    // A readable print for debugging/logging.
    function string convert2string();
        return $sformatf("wr_en=%0b rd_en=%0b din=0x%0h | dout=0x%0h full=%0b empty=%0b",
                         wr_en, rd_en, din, dout, full, empty);
    endfunction

endclass
