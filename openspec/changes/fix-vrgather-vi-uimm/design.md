## Context

The baseline is 34bd3bc. OPIVI defaults to sign extension and its gather case fails to override this. Existing gather tests only exercise immediate 3. The original reporter, davidharrishmc, supplied the exact fix in `ara-repros/vrgather-vi-uimm/fix.patch`.

## Goals / Non-Goals

Goals: correct gather immediate decoding, preserve signed OPIVI behavior, add software regression coverage, and obtain before/after RTL evidence.

Non-goals: fix out-of-range gather hangs, slides or shifts; change interfaces.

## Decisions

Use a local zero-extension override in OPIVI VRGATHER, following the reporter patch. Changing the OPIVI default would alter signed arithmetic instructions. Keep the existing test style in vrgather.c and use e8/m2 so all five-bit indices fit even at VLEN=128. Include a shortened VL case to distinguish VL from VLMAX.

For focused evidence, instantiate the real dispatcher with repository packages and a small backend handshake harness. Check all 32 immediate values, both mask settings, and signed vadd.vi controls. This avoids compiling the whole CVA6 SoC and localizes the root cause. Software compilation and end-to-end execution are separate checks; dispatcher success alone does not prove the mask unit completes.

## Risks / Trade-offs

- Full-system dependencies and toolchain may be expensive to build → record each verification level and leave unrun acceptance checks blocked.
- Out-of-range indices hit a separate known bug → software regression keeps its indices below VLMAX.
- Platform-dependent builds → provide exact commands and versions in the report.

## Planned Files

Modify dispatcher, existing gather tests and CHANGELOG.md. Add a focused dispatcher testbench/runner under hardware/tb and evidence under docs/issues/526. OpenSpec and STATE.md track progress. No migration required; rollback is a revert.
