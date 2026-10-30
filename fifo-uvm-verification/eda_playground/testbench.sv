//======================================================================
//  testbench.sv — paste this into the LEFT pane (testbench.sv)
//  Contains: interface + all UVM classes (in a package) + top module
//======================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

//----------------------------------------------------------------------
//  INTERFACE (must be outside the package)
//----------------------------------------------------------------------
interface fifo_if(input logic clk);
    logic        rst;
    logic        wr_en;
    logic        rd_en;
    logic [7:0]  din;
    logic [7:0]  dout;
    logic        full;
    logic        empty;

    // ---- assertions ----
    a_not_full_and_empty: assert property (@(posedge clk)
        !(full && empty)
    ) else $error("ASSERT: full and empty both high!");

    a_flags_known: assert property (@(posedge clk) disable iff (rst)
        !$isunknown({full, empty})
    ) else $error("ASSERT: full/empty went unknown!");

    a_reset_makes_empty: assert property (@(posedge clk)
        rst |=> empty
    ) else $error("ASSERT: FIFO not empty after reset!");
endinterface


//----------------------------------------------------------------------
//  PACKAGE: all the UVM classes
//----------------------------------------------------------------------
package fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ===== TRANSACTION =====
    class fifo_transaction extends uvm_sequence_item;
        rand bit       wr_en;
        rand bit       rd_en;
        rand bit [7:0] din;
        bit [7:0] dout;
        bit       full;
        bit       empty;

        `uvm_object_utils(fifo_transaction)

        function new(string name = "fifo_transaction");
            super.new(name);
        endfunction

        constraint c_write_bias { wr_en dist {1 := 70, 0 := 30}; }
        constraint c_read_bias  { rd_en dist {1 := 50, 0 := 50}; }

        function string convert2string();
            return $sformatf("wr_en=%0b rd_en=%0b din=0x%0h | dout=0x%0h full=%0b empty=%0b",
                             wr_en, rd_en, din, dout, full, empty);
        endfunction
    endclass

    // ===== SEQUENCE =====
    class fifo_sequence extends uvm_sequence #(fifo_transaction);
        `uvm_object_utils(fifo_sequence)
        int num_txns = 200;

        function new(string name = "fifo_sequence");
            super.new(name);
        endfunction

        task body();
            repeat (num_txns) begin
                req = fifo_transaction::type_id::create("req");
                start_item(req);
                if (!req.randomize())
                    `uvm_error("SEQ", "randomize failed")
                finish_item(req);
            end
        endtask
    endclass

    // ===== DRIVER =====
    class fifo_driver extends uvm_driver #(fifo_transaction);
        virtual fifo_if vif;
        `uvm_component_utils(fifo_driver)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
                `uvm_fatal("DRV", "No virtual interface found in config_db")
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);
                drive(req);
                seq_item_port.item_done();
            end
        endtask

        task drive(fifo_transaction t);
            @(posedge vif.clk);
            vif.wr_en <= t.wr_en;
            vif.rd_en <= t.rd_en;
            vif.din   <= t.din;
        endtask
    endclass

    // ===== MONITOR =====
    class fifo_monitor extends uvm_monitor;
        virtual fifo_if vif;
        uvm_analysis_port #(fifo_transaction) ap;
        `uvm_component_utils(fifo_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
                `uvm_fatal("MON", "No virtual interface found in config_db")
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                @(posedge vif.clk);
                if (!vif.rst) begin
                    fifo_transaction t = fifo_transaction::type_id::create("t");
                    t.wr_en = vif.wr_en;
                    t.rd_en = vif.rd_en;
                    t.din   = vif.din;
                    t.dout  = vif.dout;
                    t.full  = vif.full;
                    t.empty = vif.empty;
                    ap.write(t);
                end
            end
        endtask
    endclass

    // ===== SCOREBOARD =====
    class fifo_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(fifo_scoreboard)
        uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) analysis_export;

        bit [7:0] ref_q[$];
        bit       expect_valid;
        bit [7:0] expect_data;
        int num_checks, num_errors;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
        endfunction

        function void write(fifo_transaction t);
            if (expect_valid) begin
                num_checks++;
                if (t.dout !== expect_data) begin
                    num_errors++;
                    `uvm_error("SB", $sformatf("READ MISMATCH: expected 0x%0h, got 0x%0h",
                                               expect_data, t.dout))
                end
                expect_valid = 0;
            end
            if (t.wr_en && !t.full)
                ref_q.push_back(t.din);
            if (t.rd_en && !t.empty) begin
                expect_data  = ref_q.pop_front();
                expect_valid = 1;
            end
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("SB", $sformatf("Checks run: %0d | Errors: %0d", num_checks, num_errors), UVM_LOW)
            if (num_errors == 0)
                `uvm_info("SB", "*** TEST PASSED ***", UVM_LOW)
            else
                `uvm_error("SB", "*** TEST FAILED ***")
        endfunction
    endclass

    // ===== COVERAGE =====
    class fifo_coverage extends uvm_component;
        `uvm_component_utils(fifo_coverage)
        uvm_analysis_imp #(fifo_transaction, fifo_coverage) analysis_export;
        fifo_transaction tr;

        covergroup fifo_cg;
            cp_full:  coverpoint tr.full  { bins not_full  = {0}; bins is_full  = {1}; }
            cp_empty: coverpoint tr.empty { bins not_empty = {0}; bins is_empty = {1}; }
            cp_wr:    coverpoint tr.wr_en { bins no_wr = {0}; bins wr = {1}; }
            cp_rd:    coverpoint tr.rd_en { bins no_rd = {0}; bins rd = {1}; }
            cross_rw: cross cp_wr, cp_rd;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
            fifo_cg = new();
        endfunction

        function void write(fifo_transaction t);
            tr = t;
            fifo_cg.sample();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%", fifo_cg.get_coverage()), UVM_LOW)
        endfunction
    endclass

    // ===== AGENT =====
    class fifo_agent extends uvm_agent;
        fifo_driver                        drv;
        fifo_monitor                       mon;
        uvm_sequencer #(fifo_transaction)  seqr;
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
            drv.seq_item_port.connect(seqr.seq_item_export);
        endfunction
    endclass

    // ===== ENV =====
    class fifo_env extends uvm_env;
        fifo_agent       agt;
        fifo_scoreboard  sb;
        fifo_coverage    cov;
        `uvm_component_utils(fifo_env)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agt = fifo_agent::type_id::create("agt", this);
            sb  = fifo_scoreboard::type_id::create("sb", this);
            cov = fifo_coverage::type_id::create("cov", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            agt.mon.ap.connect(sb.analysis_export);
            agt.mon.ap.connect(cov.analysis_export);
        endfunction
    endclass

    // ===== TEST =====
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
            phase.raise_objection(this);
            seq = fifo_sequence::type_id::create("seq");
            seq.start(env.agt.seqr);
            phase.drop_objection(this);
        endtask
    endclass

endpackage


//----------------------------------------------------------------------
//  TOP MODULE
//----------------------------------------------------------------------
module fifo_tb_top;
    import uvm_pkg::*;
    import fifo_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk;

    fifo_if intf(clk);

    sync_fifo #(.WIDTH(8), .DEPTH(8)) dut (
        .clk(intf.clk), .rst(intf.rst),
        .wr_en(intf.wr_en), .rd_en(intf.rd_en), .din(intf.din),
        .dout(intf.dout), .full(intf.full), .empty(intf.empty)
    );

    initial begin
        intf.rst   = 1;
        intf.wr_en = 0;
        intf.rd_en = 0;
        intf.din   = 0;
        repeat (2) @(posedge clk);
        intf.rst = 0;
    end

    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", intf);
        run_test("fifo_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fifo_tb_top);
    end
endmodule
