// ============================================================
//  vector_tb.sv  —  Testbench for the Vector Core
//
//  SECTION 1: ALU tests (12 ops) via vector_top integration
//  SECTION 2: LSU tests (VSTORE + VLOAD x2) via direct
//             vector_lsu instantiation
//             NOTE: VLOAD/VSTORE through vector_top requires
//             stall logic (PC keeps advancing); tested directly.
//
//  Instruction encoding used by vector_controller / vector_top:
//    [31:28] op   4-bit vector_opcode_t
//    [27:23] rd   dest register
//    [22:18] rs1  source 1
//    [17:13] rs2  source 2
//    [12:11] mode LSU access mode
//    [10:0]  imm  stride immediate (sign-extended in datapath)
//
//  Test vectors:
//    vs1[lane i] = i+1  →  {1,2,3,4,5,6,7,8}
//    vs2[lane i] = 1    →  {1,1,1,1,1,1,1,1}
//    active_lanes = 7   (vl forced; see note below)
//
//  KNOWN LIMITATION: vl_lanes in vector_datapath is
//    $clog2(LANES)=3 bits wide. Default vl=VLEN/SEW=8 wraps
//    to 0, disabling all lanes. Workaround: force vl=7.
//    Fix: widen vl_lanes to $clog2(LANES+1) bits.
// ============================================================

`timescale 1ns/1ps

module vector_tb;
    import vector_pkg::*;

    localparam int AL = 8;
    logic clk = 1'b0;
    logic rst;
    always #5 clk = ~clk;//100 MHz

    //PASS / FAIL TRACKING

    int pass_count = 0;
    int fail_count = 0;
    int test_num   = 0;

    task automatic log_pass(input string name);
        $display("  [PASS] %0d. %s", ++test_num, name);
        pass_count++;
    endtask

    task automatic log_fail(
        input string       name,
        input logic [VLEN-1:0] expected,
        input logic [VLEN-1:0] got
    );
        $display("  [FAIL] %0d. %s", ++test_num, name);
        $display("            Expected : %h", expected);
        $display("            Got      : %h", got);
        fail_count++;
    endtask

    // Check a vector result
    task automatic check_vec(
        input string           name,
        input logic [VLEN-1:0] expected,
        input logic [VLEN-1:0] actual,
        input int              active_lanes
    );
        logic [VLEN-1:0] mask = '0;
        for (int i = 0; i < active_lanes; i++)
            mask[i*SEW +: SEW] = {SEW{1'b1}};
        if ((actual & mask) === (expected & mask))
            log_pass(name);
        else
            log_fail(name, expected & mask, actual & mask);
    endtask

    //  INSTRUCTION BUILDER
    //  [31:28]=op | [27:23]=rd | [22:18]=rs1 | [17:13]=rs2
    //  [12:11]=mode | [10:0]=imm
 
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

    //  DUT 1 — vector_top  (ALU integration tests)
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

    //  DUT 2 — vector_lsu  (direct LSU tests)

    vector_mem_mode_t lsu_mode  = UNIT_STRIDE;
    vector_opcode_t   lsu_op    = VADD;     // VADD = start=0 (not VLOAD/VSTORE)
    logic [15:0]      lsu_vl    = 16'd0;
    logic [31:0]      lsu_base  = 32'd0;
    logic [31:0]      lsu_stride= 32'd4;
    logic [VLEN-1:0]  lsu_index = '0;
    logic [VLEN-1:0]  lsu_sdata = '0;
    logic [VLEN-1:0]  lsu_ldata;
    logic [31:0]      lsu_maddr;
    logic             lsu_mreq, lsu_mread, lsu_mwrite;
    logic [ELEN-1:0]  lsu_mwdata;
    logic [ELEN-1:0]  lsu_mrdata;
    logic             lsu_mvalid;
    logic             lsu_done;

    vector_lsu dut_lsu (
        .clk          (clk),
        .rst          (rst),
        .mode         (lsu_mode),
        .op           (lsu_op),
        .vl           (lsu_vl),
        .base_addr    (lsu_base),
        .stride       (lsu_stride),
        .index_vector (lsu_index),
        .store_data   (lsu_sdata),
        .load_data    (lsu_ldata),
        .mem_addr     (lsu_maddr),
        .mem_req      (lsu_mreq),
        .mem_read     (lsu_mread),
        .mem_write    (lsu_mwrite),
        .mem_wdata    (lsu_mwdata),
        .mem_valid    (lsu_mvalid),
        .mem_rdata    (lsu_mrdata),
        .done         (lsu_done)
    );

    // Zero-latency combinatorial memory model for LSU
    // Reason: LSU address changes AFTER posedge (via NBA on elem_idx).
    // A 1-cycle latency model captures the OLD address and returns
    // wrong data for elements 1+.  Combinatorial model reads the
    // current address instantly, so every element gets correct data.
    logic [31:0] lsu_mem [0:1023] = '{default: 32'd0};

    assign lsu_mvalid = lsu_mreq;
    assign lsu_mrdata = (lsu_mreq && lsu_mread) ? lsu_mem[lsu_maddr >> 2] : '0;

    // Capture stores on posedge (elem_idx and addr both stable at that point)
    always_ff @(posedge clk) begin
        if (lsu_mreq && lsu_mwrite)
            lsu_mem[lsu_maddr >> 2] <= lsu_mwdata;
    end

    // Wait helper for LSU done flag (with cycle timeout)
    task automatic wait_lsu(input int timeout = 100);
        int cnt = 0;
        @(posedge clk); #1;
        while (!lsu_done && cnt < timeout) begin
            @(posedge clk); #1;
            cnt++;
        end
        if (cnt >= timeout)
            $display("  [WARN] LSU timed out after %0d cycles", timeout);
    endtask

    //  MAIN TEST SEQUENCE
    initial begin

        //  Init
        rst = 1'b1;
        // Init imem + regfile — done inside reset window below
        //  SECTION 1 — ALU INSTRUCTION TESTS (via vector_top)
        $display("");
        $display("║   SECTION 1 — ALU INSTRUCTION TESTS     ║");
        // 3 reset cycles
        repeat(3) @(posedge clk);
        #1; rst = 1'b0;
        //  Force vl = 7 to work around 3-bit truncation bug.
        //  With LANES=8, $clog2(8)=3 bits, default vl=8 → 3'b000=0
        //  → no lanes active.  Fix: widen vl_lanes to 4 bits
        // Clear entire regfile and imem
        for (int i = 0; i < MAX_VREG; i++)
            dut_top.dp.vrf.vrf[i] = '0;
        for (int i = 0; i < 256; i++)
            dut_top.imem[i] = 32'd0;   // default → regwrite=0 (NOP)

        // Load source registers
        // vs1[lane i] = i+1  →  lane0=1, lane1=2, ..., lane6=7
        // vs2[lane i] = 1    →  all ones
        for (int i = 0; i < LANES; i++) begin
            dut_top.dp.vrf.vrf[1][i*SEW +: SEW] = 32'(i + 1);
            dut_top.dp.vrf.vrf[2][i*SEW +: SEW] = 32'd1;
        end

        // Pre-load all 12 ALU instructions
        // rd = 3..14, rs1=1, rs2=2 for all
        dut_top.imem[0]  = vinstr(4'd0,  5'd3,  5'd1, 5'd2); // VADD
        dut_top.imem[1]  = vinstr(4'd1,  5'd4,  5'd1, 5'd2); // VSUB
        dut_top.imem[2]  = vinstr(4'd2,  5'd5,  5'd1, 5'd2); // VAND
        dut_top.imem[3]  = vinstr(4'd3,  5'd6,  5'd1, 5'd2); // VOR
        dut_top.imem[4]  = vinstr(4'd4,  5'd7,  5'd1, 5'd2); // VXOR
        dut_top.imem[5]  = vinstr(4'd5,  5'd8,  5'd1, 5'd2); // VSLL
        dut_top.imem[6]  = vinstr(4'd6,  5'd9,  5'd1, 5'd2); // VSRL
        dut_top.imem[7]  = vinstr(4'd7,  5'd10, 5'd1, 5'd2); // VSRA
        dut_top.imem[8]  = vinstr(4'd8,  5'd11, 5'd1, 5'd2); // VMIN
        dut_top.imem[9]  = vinstr(4'd9,  5'd12, 5'd1, 5'd2); // VMAX
        dut_top.imem[10] = vinstr(4'd10, 5'd13, 5'd1, 5'd2); // VMINU
        dut_top.imem[11] = vinstr(4'd11, 5'd14, 5'd1, 5'd2); // VMAXU

        //  Tick once per instruction, check result immediately after
        //  posedge (regfile write is synchronous; result valid +1ns)

        // --- VADD  v3 = v1 + v2  (lane i: (i+1)+1 = i+2) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'(i+2);
            check_vec("VADD  v3 = v1 + v2  (exp: 2,3,4,5,6,7,8)",
                      exp, dut_top.dp.vrf.vrf[3], AL);
        end

        // --- VSUB  v4 = v1 - v2  (lane i: (i+1)-1 = i) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'(i);
            check_vec("VSUB  v4 = v1 - v2  (exp: 0,1,2,3,4,5,6)",
                      exp, dut_top.dp.vrf.vrf[4], AL);
        end

        // --- VAND  v5 = v1 & v2  (lane i: (i+1)&1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'((i+1) & 1);
            check_vec("VAND  v5 = v1 & v2  (exp: 1,0,1,0,1,0,1)",
                      exp, dut_top.dp.vrf.vrf[5], AL);
        end

        // --- VOR   v6 = v1 | v2  (lane i: (i+1)|1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'((i+1) | 1);
            check_vec("VOR   v6 = v1 | v2  (exp: 1,3,3,5,5,7,7)",
                      exp, dut_top.dp.vrf.vrf[6], AL);
        end

        // --- VXOR  v7 = v1 ^ v2  (lane i: (i+1)^1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'((i+1) ^ 1);
            check_vec("VXOR  v7 = v1 ^ v2  (exp: 0,3,2,5,4,7,6)",
                      exp, dut_top.dp.vrf.vrf[7], AL);
        end

        // --- VSLL  v8 = v1 << v2  (shift by vs2[4:0]=1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'(i+1) << 1;
            check_vec("VSLL  v8 = v1 << 1  (exp: 2,4,6,8,10,12,14)",
                      exp, dut_top.dp.vrf.vrf[8], AL);
        end

        // --- VSRL  v9 = v1 >> v2  (shift right logical by 1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) exp[i*SEW+:SEW] = 32'(i+1) >> 1;
            check_vec("VSRL  v9 = v1 >> 1  (exp: 0,1,1,2,2,3,3)",
                      exp, dut_top.dp.vrf.vrf[9], AL);
        end

        // --- VSRA  v10 = $signed(v1) >>> v2  (arithmetic right shift by 1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++)
                exp[i*SEW+:SEW] = 32'($signed(32'(i+1)) >>> 1);
            check_vec("VSRA  v10 = v1 >>> 1 (exp: 0,1,1,2,2,3,3, signed)",
                      exp, dut_top.dp.vrf.vrf[10], AL);
        end

        // --- VMIN  v11 = min(v1,v2) signed  (min(i+1,1) = 1 always) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) begin
                automatic int a = i+1, b = 1;
                exp[i*SEW+:SEW] = ($signed(32'(a)) < $signed(32'(b))) ? 32'(a) : 32'(b);
            end
            check_vec("VMIN  v11 = min(v1,v2) signed (exp: 1,1,1,1,1,1,1)",
                      exp, dut_top.dp.vrf.vrf[11], AL);
        end

        // --- VMAX  v12 = max(v1,v2) signed  (max(i+1,1) = i+1) ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) begin
                automatic int a = i+1, b = 1;
                exp[i*SEW+:SEW] = ($signed(32'(a)) > $signed(32'(b))) ? 32'(a) : 32'(b);
            end
            check_vec("VMAX  v12 = max(v1,v2) signed (exp: 1,2,3,4,5,6,7)",
                      exp, dut_top.dp.vrf.vrf[12], AL);
        end

        // --- VMINU v13 = minu(v1,v2) unsigned ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) begin
                automatic logic [31:0] a = 32'(i+1), b = 32'd1;
                exp[i*SEW+:SEW] = (a < b) ? a : b;
            end
            check_vec("VMINU v13 = minu(v1,v2) unsigned (exp: 1,1,1,1,1,1,1)",
                      exp, dut_top.dp.vrf.vrf[13], AL);
        end

        // --- VMAXU v14 = maxu(v1,v2) unsigned ---
        @(posedge clk); #1;
        begin
            automatic logic [VLEN-1:0] exp = '0;
            for (int i = 0; i < AL; i++) begin
                automatic logic [31:0] a = 32'(i+1), b = 32'd1;
                exp[i*SEW+:SEW] = (a > b) ? a : b;
            end
            check_vec("VMAXU v14 = maxu(v1,v2) unsigned (exp: 1,2,3,4,5,6,7)",
                      exp, dut_top.dp.vrf.vrf[14], AL);
        end

        // Release forced vl
        //  SECTION 2 — LSU TESTS  (direct vector_lsu)
        //  Each test: assert reset to clear done+FSM, set inputs
        //  while reset is held, release reset to start.

        $display("");

        $display("   SECTION 2 — VSTORE / VLOAD TESTS      ");
        $display("  (Direct LSU — 0-latency memory model) ");

        //  TEST 13 — VSTORE unit stride, 4 elements
        //  Store  {1,2,3,4,...}  to base=0x100, stride=4B
        //  Expected: lsu_mem[0x40]=1, [0x41]=2, [0x42]=3, [0x43]=4

        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        // Setup while reset held
        lsu_op     = VSTORE;
        lsu_mode   = UNIT_STRIDE;
        lsu_vl     = 16'd4;
        lsu_base   = 32'h100;
        lsu_stride = 32'd4;
        for (int i = 0; i < LANES; i++)
            lsu_sdata[i*SEW +: SEW] = 32'(i + 1);   // [1,2,3,4,5,6,7,8]
        #1; rst = 1'b0;

        wait_lsu(50);

        begin
            automatic logic pass_flag = 1'b1;
            for (int i = 0; i < 4; i++) begin
                automatic int widx = (32'h100 >> 2) + i;  // 0x40+i
                if (lsu_mem[widx] !== 32'(i + 1)) begin
                    $display("    VSTORE lane %0d: expected %0d, got %0d",
                             i, i+1, lsu_mem[widx]);
                    pass_flag = 1'b0;
                end
            end
            if (pass_flag) log_pass("VSTORE unit-stride base=0x100 (4 elems → mem[64..67])");
            else           log_fail("VSTORE unit-stride base=0x100", '0, '0);
        end

        //  TEST 14 — VLOAD unit stride, 4 elements
        //  Pre-fill mem[0x80..0x83] = {100,101,102,103}
        //  Expected: lsu_ldata[0..3] = {100,101,102,103}
        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        // Pre-fill memory
        for (int i = 0; i < 4; i++)
            lsu_mem[(32'h200 >> 2) + i] = 32'(i + 100);  // 0x80+i
        // Setup
        lsu_op   = VLOAD;
        lsu_mode = UNIT_STRIDE;
        lsu_vl   = 16'd4;
        lsu_base = 32'h200;
        #1; rst = 1'b0;

        wait_lsu(50);

        begin
            automatic logic pass_flag = 1'b1;
            for (int i = 0; i < 4; i++) begin
                if (lsu_ldata[i*SEW +: SEW] !== 32'(i + 100)) begin
                    $display("    VLOAD lane %0d: expected %0d, got %0d",
                             i, i+100, lsu_ldata[i*SEW+:SEW]);
                    pass_flag = 1'b0;
                end
            end
            if (pass_flag) log_pass("VLOAD unit-stride base=0x200 (4 elems, values 100-103)");
            else           log_fail("VLOAD unit-stride base=0x200", '0, '0);
        end

        //  TEST 15 — VLOAD stride mode, stride=8B, 4 elements
        //  Pre-fill mem every 2 words from base=0x300:
        //    mem[0x300]=200, mem[0x308]=201, mem[0x310]=202, mem[0x318]=203
        //  stride = elem_idx * 8  →  byte offsets 0,8,16,24
        //  Expected: lsu_ldata[0..3] = {200,201,202,203}

        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        // Pre-fill every 2 words
        for (int i = 0; i < 4; i++)
            lsu_mem[(32'h300 >> 2) + i*2] = 32'(i + 200); // 0xC0, 0xC2, 0xC4, 0xC6
        // Setup
        lsu_op     = VLOAD;
        lsu_mode   = STRIDE;
        lsu_vl     = 16'd4;
        lsu_base   = 32'h300;
        lsu_stride = 32'd8;  // 8-byte stride
        #1; rst = 1'b0;

        wait_lsu(50);

        begin
            automatic logic pass_flag = 1'b1;
            for (int i = 0; i < 4; i++) begin
                if (lsu_ldata[i*SEW +: SEW] !== 32'(i + 200)) begin
                    $display("    VLOAD-STRIDE lane %0d: expected %0d, got %0d",
                             i, i+200, lsu_ldata[i*SEW+:SEW]);
                    pass_flag = 1'b0;
                end
            end
            if (pass_flag) log_pass("VLOAD stride=8B base=0x300 (4 elems, values 200-203)");
            else           log_fail("VLOAD stride=8B base=0x300", '0, '0);
        end

        //  SUMMARY

        $display("");
        $display("╔══════════════════════════════════════════╗");
        $display("║              TEST SUMMARY                ║");
        $display("╠══════════════════════════════════════════╣");
        $display("║  Total tests : %2d                       ║", pass_count + fail_count);
        $display("║  Passed      : %2d                       ║", pass_count);
        $display("║  Failed      : %2d                       ║", fail_count);
        $display("╚══════════════════════════════════════════╝");
        $display("");

        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d TEST(S) FAILED — check output above ***", fail_count);
        $display("");

        $finish;
    end
    //  WATCHDOG — kill sim if hung

    initial begin
        #200_000;
        $display("[ERROR] Simulation watchdog timeout — check for hang");
        $finish;
    end

endmodule
