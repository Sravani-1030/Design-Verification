//======================================================================
//  design.sv  — paste this into the RIGHT pane (design.sv) on EDA Playground
//  The DUT: a synchronous FIFO
//======================================================================

module sync_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
) (
    input  logic             clk,
    input  logic             rst,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic             full,
    output logic             empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH):0] wr_ptr;
    logic [$clog2(DEPTH):0] rd_ptr;

    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[$clog2(DEPTH)]     != rd_ptr[$clog2(DEPTH)]) &&
                   (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]);

    always_ff @(posedge clk) begin
        if (rst)
            wr_ptr <= '0;
        else if (wr_en && !full) begin
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

endmodule
