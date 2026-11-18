## Why

Ara sign-extends the unsigned five-bit index of `vrgather.vi`. Indices 16–31 consequently reach the backend as huge unsigned values and can hang the mask unit. The reporter has already identified the missing zero extension and supplied a patch.

## What Changes

- Apply the reporter's zero-extension fix in the OPIVI gather case.
- Add software regression coverage for immediate indices across the sign boundary, including masking and a source index beyond VL but within VLMAX.
- Exercise the real dispatcher RTL before and after the fix with an exhaustive immediate check and signed-immediate controls where feasible.
- Record verification evidence and update the changelog.

## Capabilities

### New Capabilities

- `vrgather-unsigned-immediate`: Decode all gather immediate indices as unsigned without changing signed arithmetic immediates.

### Modified Capabilities

None.

## Impact

`hardware/src/ara_dispatcher.sv`, `apps/riscv-tests/isa/rv64uv/vrgather.c`, focused testbench/runner under `hardware/tb`, and `CHANGELOG.md`. Work notes and acceptance evidence live under `docs/issues/526/`. No production dependency or interface change. The separate mask-unit out-of-range defect is outside this change.
