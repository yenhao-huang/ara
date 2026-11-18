# Ara 526: unsigned immediate gather

- Related issue: [Ara 526](https://redirect.github.com/pulp-platform/ara/issues/526)
- Baseline: `34bd3bc152421b4601a7bf3d6e8e91ffb545c99e`
- Fork: `yenhao-huang/ara`, branch `agent/fix-526`
- Date: 2026-11-18
- Implementation commit: `e708ec64cb3914d261cd4b6cf7b16ac1db4a7c0c`
- Fork PR: https://github.com/yenhao-huang/ara/pull/1 (OPEN, draft; base main)

## Acceptance criteria

| ID | Expected behavior | Verification / evidence |
| --- | --- | --- |
| AC-1 | Gather scalar operand equals unsigned index 0–31 for both mask encodings | Same real-dispatcher RTL regression on baseline and fix |
| AC-2 | Signed vadd immediate remains sign-extended for both mask encodings | 64 arithmetic control checks in the same RTL test |
| AC-3 | Software gathers at 15/16/31 broadcast source values, including index > VL and masked-undisturbed destinations | Compile existing vrgather.c plus new case; run on Ara when available |

## Environment

Windows host; Docker container `ara526-dev` based on existing `codex-sandbox:local`, Debian 12 amd64. Worktree mounted at `/work`. OpenSpec CLI 1.6.0, Verilator 5.006, Debian Clang/LLD 14.0.6, QEMU riscv64 7.2.22. Container packages installed with `apt-get install verilator clang lld qemu-user`. Native C++ build uses two jobs.

Dispatcher dependency revisions match `Bender.lock`: CVA6 `99eac9a649001bdf5b8f9da52e0ca73d5c48db1c`, common_cells `c27bce39ebb2e6bae52f60960814a2afca7bd4cb`, fpnew `e5aa6a01b5bbe1675c3aa8872e1203413ded83d1`, AXI `853ede23b2a9837951b74dbdc6d18c3eef5bac7d` (only axi_pkg.sv fetched). These are local ignored dependencies, not new production dependencies. Standard setup is `make -C hardware checkout`; this focused test only needs those four packages.

## Reproduce

The focused test drives real vsetvli and OPIVI instruction encodings through the dispatcher request handshake and checks its registered backend output. It does not replace or reimplement the decoder. Interface structs are taken directly from ara.sv at build time.

```sh
python3 hardware/tb/run_dispatcher_immediate.py
```

Baseline result: **reproduced at the dispatcher boundary**. The runner returned exit 1 after the simulated RTL aborted with 32/128 checks failed. All failures were gather immediate encodings 16–31, with vm=0 and vm=1. All 64 signed arithmetic controls passed. Example actual output:

```text
FAIL arithmetic=0 vm=0 imm=16 valid=1 scalar=fffffffffffffff0 expected=0000000000000010
32/128 immediate checks failed
```

The first two attempts failed during compilation because the harness lacked AXI and counter dependencies. Those setup failures are not bug-reproduction evidence. The completed baseline run above used unmodified production RTL. A copy remains at `hardware/build/ara_dispatcher.baseline.sv` locally; raw output is `hardware/build/dispatcher-baseline.log`.

No full-system mask-unit hang has been reproduced locally. This test directly verifies the invalid operand that causes it.

## Diagnosis and fix

The OPIVI default sign-extends `rs1[19:15]`; VRGATHER does not override it. Encodings 16–31 become XLEN-sized negative values interpreted as huge unsigned indices. A separate mask-unit out-of-range hang is tracked in [Ara 477](https://redirect.github.com/pulp-platform/ara/pull/477). It is not modified here.

Credit: **davidharrishmc** supplied the root cause, original reproducer and [zero-extension patch](https://github.com/davidharrishmc/ara-repros/blob/main/vrgather-vi-uimm/fix.patch). This change integrates that local override and adds regression coverage; it is not an independently discovered fix. Related slide and shift changes were inspected and are outside scope.

| File | Change | Requirement |
| --- | --- | --- |
| hardware/src/ara_dispatcher.sv | Local zero-extension override in OPIVI only | AC-1 |
| apps/riscv-tests/isa/rv64uv/vrgather.c | Add test case 7, broadcast and masking checks | AC-3 |
| hardware/tb/ara_dispatcher_immediate_tb.sv | Exhaustive gather and signed-vadd control test | AC-1, AC-2 |
| hardware/tb/run_dispatcher_immediate.py | Compile actual RTL with locked dependencies | AC-1, AC-2 |
| hardware/tb/vrgather_reference_start.c | Minimal Linux-user entry point for existing case 7 and eight golden comparisons | AC-3 test validation |
| CHANGELOG.md | Record correction | Documentation |
| openspec/, STATE.md, this report | Plan, acceptance evidence and resumable state | All |

## Regression and fixed demo

The same runner on the fixed source returned **exit 0**:

```text
PASS: 128 dispatcher immediate checks (gather and signed vadd, vm=0/1)
```

Command: `python3 hardware/tb/run_dispatcher_immediate.py`. Local raw output: `hardware/build/dispatcher-fixed.log`. The harness never substitutes a software decoder. Baseline/fix use the same dependency versions, VLEN=512 and four lanes. Verilator reports existing production/dependency width warnings; they are nonfatal in this harness. No production warnings were suppressed individually or production code modified to accommodate the harness.

The entire changed vrgather.c compiled to a RISC-V object with exit 0:

```sh
clang --target=riscv64-unknown-elf -march=rv64gcv -mabi=lp64d \
  -ffreestanding -O2 -fno-vectorize -fno-slp-vectorize \
  -Iapps/common -Iapps/riscv-tests/isa/macros/vector \
  -c apps/riscv-tests/isa/rv64uv/vrgather.c -o hardware/build/vrgather.o
```

The new TEST_CASE7 ran in QEMU at VLEN=128, 512 and 1024; **eight comparisons passed at each width, exit 0**. This validates the test inputs, expected broadcasts, index > VL case, scalar control and mask-undisturbed expectations on an independent RVV implementation. It does not execute Ara RTL.

```sh
mkdir -p hardware/build
clang --target=riscv64-linux-gnu -march=rv64gcv -mabi=lp64d \
  -ffreestanding -O2 -fno-vectorize -fno-slp-vectorize \
  -ffunction-sections -fdata-sections -mno-relax \
  -Iapps/common -Iapps/riscv-tests/isa/macros/vector -Dmain=ara_test_main \
  -c apps/riscv-tests/isa/rv64uv/vrgather.c -o hardware/build/vrgather-reference.o
clang --target=riscv64-linux-gnu -march=rv64gcv -mabi=lp64d \
  -ffreestanding -O2 -fno-vectorize -fno-slp-vectorize -mno-relax \
  -nostdlib -static -fuse-ld=lld -Wl,--gc-sections,-e,_start \
  hardware/tb/vrgather_reference_start.c hardware/build/vrgather-reference.o \
  -o hardware/build/vrgather-reference.elf
for vlen in 128 512 1024; do
  qemu-riscv64 -cpu rv64,v=true,vlen=$vlen,elen=64,vext_spec=v1.0 \
    hardware/build/vrgather-reference.elf || exit $?
done
```

Output for each VLEN: `PASS: TEST_CASE7 (8 comparisons)`. The small entry point invokes the real case and checks its failure counter plus number of completed comparisons. It avoids replacing the tests' vector operations or their golden comparisons. Only console formatting and memcpy are provided locally. The existing whole vrgather suite was not executed in QEMU because some old cases require larger VLEN; no pass is claimed for them.

Additional static checks: `openspec validate fix-vrgather-vi-uimm --strict` passed; `git diff --check` passed. Generated builds and raw logs stay under ignored `hardware/build/` and are excluded from commits.

## Acceptance results

| ID | Status | Evidence / remaining work |
| --- | --- | --- |
| AC-1 | passed | Baseline 32/128 failures; fixed 128/128 passed in real dispatcher RTL |
| AC-2 | passed | All 64 signed-vadd controls passed on both versions |
| AC-3 | blocked | C compilation and QEMU golden validation passed; full Ara SoC execution remains unrun |

Full-system limitation: the dedicated environment has the focused dispatcher dependencies, not the complete CVA6/Ara SoC dependency checkout and built `Vara_tb_verilator` model. The original standalone reporter ELF and the full existing gather suite have not been executed on Ara here. Required follow-up is the existing `riscv_tests_simv` job or a full-system run of `rv64uv-ara-vrgather`. Dispatcher-level correctness is verified; full integration acceptance remains incomplete.

Diff review: confirmed the only production RTL change is inside OPIVI VRGATHER; OPIVX scalar input and signed-immediate defaults are unchanged. The new mask test explicitly uses `tu, mu` rather than relying on the existing VSET macro's `ta, ma`. Test indices remain below VLMAX so they do not rely on the separate out-of-range fix.

PR / CI: fork draft PR 1 was created and read back, with head branch `agent/fix-526`. Remote branch SHA was independently verified with `git ls-remote --heads https://github.com/yenhao-huang/ara.git agent/fix-526`. GitHub reports no checks/runs and zero registered workflows on the fork at delivery; no CI success is claimed. Only the personal fork was written. Full integration acceptance remains incomplete, and the worktree is retained.
