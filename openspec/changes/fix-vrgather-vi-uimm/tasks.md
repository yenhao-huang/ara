## 1. Reproduce

- [x] 1.1 Read issue, timeline, reporter patch, repository rules and baseline.
- [x] 1.2 Run a focused real-dispatcher regression on the unmodified baseline and record failure.

## 2. Implement

- [x] 2.1 Apply the local unsigned immediate override with attribution in the report.
- [x] 2.2 Extend software gather tests across the sign boundary and masked/short-VL cases.
- [x] 2.3 Update CHANGELOG and document changed files.

## 3. Verify and deliver

- [x] 3.1 Run the same dispatcher test on the fix, including signed arithmetic controls.
- [ ] 3.2 Compile and execute the software regression where supported; record any blocked end-to-end check.
- [x] 3.3 Validate OpenSpec, inspect the diff and record acceptance evidence.
- [x] 3.4 Commit, push and verify a fork-only PR; inspect CI state.
