//======================================================================
//  fifo_env.sv — bundles agent + scoreboard
//======================================================================
//  Same pattern as the agent, one level up. connect_phase wires the
//  monitor's analysis port to the scoreboard's inbox.
//======================================================================

class fifo_env extends uvm_env;

    fifo_agent       agt;
    fifo_scoreboard  sb;
    fifo_coverage    cov;                 // NEW: coverage collector

    `uvm_component_utils(fifo_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = fifo_agent::type_id::create("agt", this);
        sb  = fifo_scoreboard::type_id::create("sb", this);
        cov = fifo_coverage::type_id::create("cov", this);   // NEW
    endfunction

    function void connect_phase(uvm_phase phase);
        // the monitor's analysis port BROADCASTS to BOTH listeners:
        agt.mon.ap.connect(sb.analysis_export);    // -> scoreboard (checks correctness)
        agt.mon.ap.connect(cov.analysis_export);   // -> coverage   (records what was tested)
    endfunction

endclass
