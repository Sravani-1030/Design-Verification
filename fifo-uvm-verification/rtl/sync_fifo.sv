//======================================================================
//  sync_fifo.sv  — Synchronous FIFO (Design Under Test)
//======================================================================
//  A first-in-first-out queue with one clock.
//  Parameterizable width and depth (defaults: 8-bit data, 8 entries).
//
//  This is the DUT — the design you (the DV engineer) will VERIFY.
//  In a real job, an RTL designer writes this and hands it to you.
//======================================================================

module sync_fifo #(
    parameter int WIDTH = 8,          // data width in bits
    parameter int DEPTH = 8           // number of entries the FIFO holds
) (
    input  logic             clk,
    input  logic             rst,     // synchronous reset, active high
    input  logic             wr_en,   // request to write din
    input  logic             rd_en,   // request to read dout
    input  logic [WIDTH-1:0] din,     // data to write in
    output logic [WIDTH-1:0] dout,    // data read out (oldest)
    output logic             full,    // 1 when FIFO cannot accept more
    output logic             empty    // 1 when FIFO has nothing to give
);

    // ---- storage + pointers ----
    // The memory: DEPTH slots, each WIDTH bits wide.
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers into the memory. We need one extra bit (clog2(DEPTH)+1)
    // so we can tell "full" apart from "empty" (both can have wr==rd low bits).
    logic [$clog2(DEPTH):0] wr_ptr;   // where the next write goes
    logic [$clog2(DEPTH):0] rd_ptr;   // where the next read comes from

    // ---- flags ----
    // The low bits of the pointers index the memory; the top bit tracks
    // "wrapped around" so full vs empty is unambiguous.
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[$clog2(DEPTH)]     != rd_ptr[$clog2(DEPTH)]) &&
                   (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]);

    // ---- write logic ----
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin        // only write if NOT full
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // ---- read logic ----
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else if (rd_en && !empty) begin        // only read if NOT empty
            dout   <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

endmodule
