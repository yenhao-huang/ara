// SPDX-License-Identifier: SHL-0.51
// Focused regression for unsigned gather and signed arithmetic immediates.
module ara_dispatcher_immediate_tb;
  import ara_pkg::*;
  import rvv_pkg::*;
  import ara_dispatcher_test_pkg::*;

  logic clk = 0;
  logic rst_n = 0;
  always #5 clk = ~clk;

  accelerator_req_t acc_req;
  accelerator_resp_t acc_resp;
  ara_req_t backend_req;
  logic backend_valid;
  int failures = 0;
  int checks = 0;

  ara_dispatcher #(
    .NrLanes(4), .VLEN(VLEN), .CVA6Cfg(Cfg),
    .ara_req_t(ara_req_t), .ara_resp_t(ara_resp_t),
    .accelerator_req_t(accelerator_req_t),
    .accelerator_resp_t(accelerator_resp_t)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n), .acc_req_i(acc_req), .acc_resp_o(acc_resp),
    .ara_req_o(backend_req), .ara_req_valid_o(backend_valid),
    .ara_req_ready_i(1'b1), .ara_resp_i(ara_resp_t'('0)),
    .ara_resp_valid_i(1'b0), .ara_idle_i(1'b1),
    .fflags_ex_i('0), .fflags_ex_valid_i('0),
    .lsu_ex_flush_o(), .lsu_ex_flush_done_i(1'b1),
    .vxsat_flag_i('0), .alu_vxrm_o(), .core_st_pending_o(),
    .load_complete_i(1'b0), .store_complete_i(1'b0), .store_pending_i(1'b0)
  );

  // Drive a genuine instruction through the CVA6 request handshake.
  task automatic issue(input logic [31:0] insn, input logic [63:0] rs1 = 0);
    int cycles;
    @(negedge clk);
    acc_req = '0;
    acc_req.insn = insn;
    acc_req.rs1 = rs1;
    acc_req.req_valid = 1;
    acc_req.resp_ready = 1;
    #1;
    cycles = 0;
    while (!acc_resp.req_ready) begin
      @(negedge clk);
      #1;
      cycles++;
      if (cycles > 20) $fatal(1, "Dispatcher handshake timeout");
    end
    if (acc_resp.exception.valid) $fatal(1, "Unexpected illegal instruction %h", insn);
    @(posedge clk);
    #1;
  endtask

  initial begin
    acc_req = '0;
    repeat (3) @(negedge clk);
    rst_n = 1;
    // vsetvli x1, x1, e8, m1, tu, mu; AVL=32, VLMAX=64.
    issue(32'h0000f0d7, 32);
    @(negedge clk);
    acc_req.req_valid = 0;

    for (int arithmetic = 0; arithmetic < 2; arithmetic++) begin
      for (int vm = 0; vm < 2; vm++) begin
        for (int imm = 0; imm < 32; imm++) begin
          logic [63:0] expected;
          logic [5:0] func6;
          func6 = (arithmetic != 0) ? 6'b000000 : 6'b001100;
          expected = (arithmetic != 0) ? 64'($signed(5'(imm))) : 64'(imm);
          // vadd.vi/vrgather.vi v8, v24, imm[, v0.t].
          issue({func6, 1'(vm), 5'd24, 5'(imm), 3'b011, 5'd8, 7'h57});
          checks++;
          if (!backend_valid || backend_req.scalar_op !== expected ||
              !backend_req.use_scalar_op || backend_req.vm != 1'(vm) ||
              backend_req.op != ((arithmetic != 0) ? VADD : VRGATHER)) begin
            $display("FAIL arithmetic=%0d vm=%0d imm=%0d valid=%b scalar=%h expected=%h",
                     arithmetic, vm, imm, backend_valid, backend_req.scalar_op, expected);
            failures++;
          end
        end
      end
    end
    if (failures != 0) $fatal(1, "%0d/%0d immediate checks failed", failures, checks);
    $display("PASS: %0d dispatcher immediate checks (gather and signed vadd, vm=0/1)", checks);
    $finish;
  end

  initial begin
    #100000;
    $fatal(1, "Testbench timeout");
  end
endmodule
