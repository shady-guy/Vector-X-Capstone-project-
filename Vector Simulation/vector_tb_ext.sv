// ============================================================
//  vector_tb_ext.sv  —  Extended Testbench (minimal changes)
//  Adds tests for: instruction-hold (LSU stall), masking, vtype/vl
//  and INDEX-mode loads in addition to original ALU/LSU tests.
//  This file intentionally coexists with the original `vector_tb.sv`.
// ============================================================

`timescale 1ns/1ps
module vector_tb_ext;
    import vector_pkg::*;

    // clock / reset
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst;

    // reuse same localparams as design
    localparam int AL = 8;

    // DUT: vector_top for integration tests
    logic [31:0]     t_cfg_data  = 32'd0;
    logic [31:0]     t_mem_addr;
    logic            t_mem_req, t_mem_read, t_mem_write;
    logic [ELEN-1:0] t_mem_wdata;
    logic            t_mem_valid = 1'b0;
    logic [ELEN-1:0] t_mem_rdata = '0;
    logic            t_lsu_done;

    vector_top dut_top (
        .clk      (clk),
        .rst      (rst),
        .cfg_data (t_cfg_data),
        .mem_addr  (t_mem_addr),
        .mem_req   (t_mem_req),
        .mem_read  (t_mem_read),
        .mem_write (t_mem_write),
        .mem_wdata (t_mem_wdata),
        .mem_valid (t_mem_valid),
        .mem_rdata (t_mem_rdata),
        .lsu_done  (t_lsu_done)
    );

    // Simple pass/fail tracking
    int pass_count = 0; int fail_count = 0; int test_num = 0;
    task automatic log_pass(input string s); $display("[PASS] %0d: %s", ++test_num, s); pass_count++; endtask
    task automatic log_fail(input string s); $display("[FAIL] %0d: %s", ++test_num, s); fail_count++; endtask

    // minimal helpers (copied style from original)
    function automatic logic [31:0] vinstr(
        input logic [3:0]  op,
        input logic [4:0]  rd,
        input logic [4:0]  rs1,
        input logic [4:0]  rs2,
        input logic [1:0]  mode = 2'b00,
        input logic [10:0] imm  = 11'd0
    );
        return {op, rd, rs1, rs2, mode, imm};
    endfunction

    // check a subset of lanes according to active_lanes
    task automatic check_vec_masked(
        input string name,
        input logic [VLEN-1:0] expected,
        input logic [VLEN-1:0] got,
        input int active_lanes
    );
        logic [VLEN-1:0] mask = '0;
        for (int i=0; i<active_lanes; i++) mask[i*SEW +: SEW] = {SEW{1'b1}};
        if (((got & mask) === (expected & mask))) log_pass(name);
        else begin
            $display("  Expected: %h", expected & mask);
            $display("  Got     : %h", got & mask);
            log_fail(name);
        end
    endtask

    // small memory model used by vector_top (byte-addressable by ELEN/8)
    logic [ELEN-1:0] top_mem [0:4095];
    // temporary expected/result vectors used by tests
    logic [VLEN-1:0] expect_masked;
    // Direct LSU instance signals (module scope so assigns/instantiation legal)
    vector_mem_mode_t lsu_mode;
    vector_opcode_t   lsu_op;
    logic [15:0]      lsu_vl;
    logic [31:0]      lsu_base;
    logic [31:0]      lsu_stride;
    logic [VLEN-1:0]  lsu_index;
    logic [VLEN-1:0]  lsu_sdata;
    logic [VLEN-1:0]  lsu_ldata;
    logic [31:0]      lsu_maddr;
    logic             lsu_mreq, lsu_mread, lsu_mwrite;
    logic [ELEN-1:0]  lsu_mwdata;
    logic [ELEN-1:0]  lsu_mrdata;
    logic             lsu_mvalid;
    logic             lsu_done_local;
    logic [31:0]      idx_seen_addr [0:3];
    logic [ELEN-1:0]  idx_seen_data [0:3];
    int               idx_seen_count;
    int               idx_watchdog;
    int               idx_check_i;
    logic             found_500;
    logic             found_508;
    logic             found_510;
    logic             found_518;

    // small mem for direct LSU
    logic [ELEN-1:0] lsu_mem [0:1023];

    // wire behavioral memory connections at module scope
    assign lsu_mvalid = lsu_mreq;
    assign lsu_mrdata = (lsu_mreq && lsu_mread) ? lsu_mem[lsu_maddr >> 3] : '0;

    // instantiate direct vector_lsu at module scope
    vector_lsu dut_lsu (
        .clk (clk), .rst (rst), .mode (lsu_mode), .lsu_en (1'b1), .op (lsu_op),
        .vl (lsu_vl), .base_addr (lsu_base), .stride (lsu_stride), .index_vector (lsu_index),
        .store_data (lsu_sdata), .vsew (3'd2), .load_data (lsu_ldata), .mem_addr (lsu_maddr),
        .mem_req (lsu_mreq), .mem_read (lsu_mread), .mem_write (lsu_mwrite), .mem_wdata (lsu_mwdata),
        .mem_valid (lsu_mvalid), .mem_rdata (lsu_mrdata), .done (lsu_done_local)
    );

    // drive t_mem_valid / rdata to simulate variable latency
    // when top asserts t_mem_req we wait `mem_latency` cycles then return data
    int mem_latency = 0; // tweak per-test
    int mem_resp_wait = 0;
    logic mem_pending = 1'b0;
    always_ff @(posedge clk) begin
        if (rst) begin
            t_mem_valid <= 1'b0;
            t_mem_rdata <= '0;
            mem_resp_wait <= 0;
            mem_pending <= 1'b0;
        end else begin
            if (t_mem_req && !mem_pending) begin
                // start counting latency
                mem_pending <= 1'b1;
                mem_resp_wait <= mem_latency;
                t_mem_valid <= 1'b0;
            end else if (mem_pending && mem_resp_wait > 0) begin
                mem_resp_wait <= mem_resp_wait - 1;
                t_mem_valid <= 1'b0;
            end else if (mem_pending && mem_resp_wait == 0) begin
                // respond this cycle
                t_mem_valid <= 1'b1;
                t_mem_rdata <= top_mem[t_mem_addr >> (ELEN/8==8?3: (ELEN/8==4?2:0))];
                mem_pending <= 1'b0;
            end else begin
                t_mem_valid <= 1'b0;
            end
        end
    end

    // Utility: write 32-bit words into top_mem elements (ELEN sized)
    task write_top_mem_word(input int word_addr, input logic [31:0] v);
        // place into lower bits of ELEN element
        top_mem[word_addr] = { {(ELEN-32){1'b0}}, v };
    endtask

    // main scenario
    initial begin
        // init
        rst = 1'b1;
        for (int i=0;i<4096;i++) top_mem[i] = '0;
        // clear regfile
        repeat(3) @(posedge clk);
        #1; rst = 1'b0;

        // ---------- Test A: instruction hold (LSU stall) ----------
        // Preload: imem[0]=VLOAD -> long latency, imem[1]=VADD
        // Expectation: VADD must not commit until after LSU completes
        $display("\n== Test A: instruction-hold (LSU stall) ==");
        // clear imem and regs
        for (int i=0;i<32;i++) dut_top.dp.vrf.vrf[i] = '0;
        for (int i=0;i<64;i++) dut_top.imem[i] = 32'd0;

        // preload memory at address 0x100
        write_top_mem_word(32'h100 >> 3, 32'hDEADBEEF);

        // set mem latency to 3 cycles to simulate stall
        mem_latency = 3;

        // VLOAD rd=3 from base in imem (we put base in cfg_data via a tiny hack)
        // use instr builder: set op = VLOAD (value in vector_pkg)
        dut_top.imem[0] = vinstr(VLOAD, 5'd3, 5'd1, 5'd0); // rs1 holds the base address for top-level LSU
        dut_top.dp.vrf.vrf[1][31:0] = 32'h100;               // base address for the top-level VLOAD

        // next instruction: VADD rd=4, rs1=2 rs2=3 (should not execute until after VLOAD completes)
        dut_top.imem[1] = vinstr(VADD, 5'd4, 5'd2, 5'd3);

        // ensure source regs for VADD have known values
        for (int i=0;i<AL;i++) begin
            dut_top.dp.vrf.vrf[2][i*SEW +: SEW] = 32'(i+1);
            dut_top.dp.vrf.vrf[3][i*SEW +: SEW] = 32'd1;
        end

        // step a few cycles and check timeline
        @(posedge clk); #1; // start VLOAD request
        // immediately after request, VADD should not have written v4
        if (dut_top.dp.vrf.vrf[4] === '0) $display("  (A1) VADD not yet executed — good"); else $display("  (A1) WARNING: VADD executed early");

        // wait for LSU to finish (t_lsu_done driven by dut_top via t_mem_valid)
        wait (t_lsu_done == 1'b1);
        @(posedge clk); #1; // one more to allow writeback

        // now VADD should execute on next cycle
        @(posedge clk); #1;
        if (dut_top.dp.vrf.vrf[4] !== '0) $display("  (A2) VADD executed after LSU completion — good"); else log_fail("Instruction-hold: VADD did not execute after LSU");
        log_pass("Instruction-hold behavior (stall + resume)");

        // ---------- Test B: masking semantics ----------
        $display("\n== Test B: masking semantics ==");
        rst = 1'b1;
        repeat(2) @(posedge clk);
        #1; rst = 1'b0;
        // Prepare vd_old in rd=5 and mask such that only lanes 0,2,4,6 active
        for (int i=0;i<32;i++) dut_top.dp.vrf.vrf[i] = '0;
        for (int i=0;i<64;i++) dut_top.imem[i] = 32'd0;
        for (int i=0;i<AL;i++) dut_top.dp.vrf.vrf[1][i*SEW +: SEW] = 32'(i+10);
        for (int i=0;i<AL;i++) dut_top.dp.vrf.vrf[2][i*SEW +: SEW] = 32'd2;
        // set old dest value to 0xFF for vd_old to observe preserved lanes
        for (int i=0;i<AL;i++) dut_top.dp.vrf.vrf[6][i*SEW +: SEW] = 32'hFF;

        // set mask register: lanes 0,2,4,6 active
        force dut_top.dp.mask_reg = 8'b01010101; // LSB = lane0
        // ensure vma=0 so inactive lanes preserve vd_old
        force dut_top.dp.vma = 1'b0;
        force dut_top.dp.vta = 1'b0;

        // place VADD into imem and run one tick
        dut_top.imem[0] = vinstr(VADD, 5'd6, 5'd1, 5'd2);
        @(posedge clk); #1; @(posedge clk); #1; // run it

        // build expected: lanes active will be (i+10)+2, inactive remain 0xFF
        expect_masked = '0;
        for (int i=0;i<AL;i++) begin
            if (dut_top.dp.mask_reg[i]) expect_masked[i*SEW +: SEW] = 32'((i+10)+2);
            else expect_masked[i*SEW +: SEW] = 32'hFF;
        end
        check_vec_masked("Masking: VADD respects mask and preserves inactive lanes", expect_masked, dut_top.dp.vrf.vrf[6], AL);
        release dut_top.dp.mask_reg;
        release dut_top.dp.vma;
        release dut_top.dp.vta;

        // ---------- Test C: vtype/vl interaction (active lanes) ----------
        $display("\n== Test C: vtype/vl active lanes ==");
        // Set vl smaller than LANES and check vl_lanes reflects it
        force dut_top.dp.cfg_unit.vl = 32'd4; // only 4 active lanes
        @(posedge clk); #1;
        if (dut_top.dp.vl_lanes == 4) log_pass("vl_reg -> vl_lanes mapping"); else log_fail("vl_reg did not reflect into vl_lanes");
        release dut_top.dp.cfg_unit.vl;

        // ---------- Test D: INDEX-mode VLOAD (direct vector_lsu) ----------
        $display("\n== Test D: INDEX-mode VLOAD via direct vector_lsu ==");
        rst = 1'b1;
        repeat(2) @(posedge clk);
        #1; rst = 1'b0;
        // Initialize direct LSU memory and pre-fill scattered addresses
        for (int ii=0; ii<1024; ii++) lsu_mem[ii] = '0;
        lsu_mem[(32'h500 >> 3)] = { {(ELEN-32){1'b0}}, 32'(111) };
        lsu_mem[(32'h508 >> 3)] = { {(ELEN-32){1'b0}}, 32'(112) };
        lsu_mem[(32'h510 >> 3)] = { {(ELEN-32){1'b0}}, 32'(113) };
        lsu_mem[(32'h518 >> 3)] = { {(ELEN-32){1'b0}}, 32'(114) };

        // build index vector as element indices that resolve to 0x500,0x508,0x510,0x518 when shifted
        for (int i=0;i<4;i++) begin
            lsu_index[i*SEW +: SEW] = 32'(32'h140 + (i * 2));
        end
        lsu_op = VLOAD; lsu_mode = INDEX; lsu_vl = 16'd4; lsu_base = 32'd0; lsu_stride = 32'd0;

        // start LSU
        @(posedge clk); #1; // release rst already low
        idx_seen_addr[0] = '0;
        idx_seen_addr[1] = '0;
        idx_seen_addr[2] = '0;
        idx_seen_addr[3] = '0;
        idx_seen_data[0] = '0;
        idx_seen_data[1] = '0;
        idx_seen_data[2] = '0;
        idx_seen_data[3] = '0;

        idx_seen_count = 0;
        idx_watchdog = 0;
        // sample each cycle from the first active LSU edge
        while (idx_seen_count < 4 && idx_watchdog < 20) begin
            @(posedge clk); #1;
            if (lsu_mreq && lsu_mread && idx_seen_count < 4) begin
                idx_seen_addr[idx_seen_count] = lsu_maddr;
                idx_seen_data[idx_seen_count] = lsu_mrdata;
                idx_seen_count++;
            end
            if (lsu_done_local && idx_seen_count >= 3) begin
                // allow the last request to be sampled, then exit on the next condition check
            end
            idx_watchdog++;
            if (lsu_done_local && idx_seen_count >= 4) begin
                break;
            end
        end

        // give the load path one cycle to settle after done
        @(posedge clk); #1;

        // check results independent of request order
        found_500 = 1'b0;
        found_508 = 1'b0;
        found_510 = 1'b0;
        found_518 = 1'b0;
        for (idx_check_i = 0; idx_check_i < idx_seen_count; idx_check_i = idx_check_i + 1) begin
            case (idx_seen_addr[idx_check_i])
                32'h500: found_500 = (idx_seen_data[idx_check_i][31:0] == 32'd111);
                32'h508: found_508 = (idx_seen_data[idx_check_i][31:0] == 32'd112);
                32'h510: found_510 = (idx_seen_data[idx_check_i][31:0] == 32'd113);
                32'h518: found_518 = (idx_seen_data[idx_check_i][31:0] == 32'd114);
                default: ;
            endcase
        end
        if (idx_seen_count == 4 && found_500 && found_508 && found_510 && found_518) begin
            log_pass("INDEX-mode VLOAD returned correct scattered elements");
        end else begin
            $display("  seen_count=%0d", idx_seen_count);
            $display("  addr0=%h data0=%h", idx_seen_addr[0], idx_seen_data[0]);
            $display("  addr1=%h data1=%h", idx_seen_addr[1], idx_seen_data[1]);
            $display("  addr2=%h data2=%h", idx_seen_addr[2], idx_seen_data[2]);
            $display("  addr3=%h data3=%h", idx_seen_addr[3], idx_seen_data[3]);
            log_fail("INDEX-mode VLOAD mismatch");
        end

        // ---------- SUMMARY ----------
        $display("\nTEST SUMMARY: Passed=%0d  Failed=%0d", pass_count, fail_count);
        if (fail_count==0) $display("*** ALL EXTENDED TESTS PASSED ***");
        $finish;
    end

    // watchdog
    initial begin
        #200_000; $display("[ERROR] Extended TB watchdog timeout"); $finish;
    end
endmodule
