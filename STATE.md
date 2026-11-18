# Ara immediate-gather run state

Run ID: ara-526-2026-11-18
Issue: https://redirect.github.com/pulp-platform/ara/issues/526
Repository / base: yenhao-huang/ara / 34bd3bc152421b4601a7bf3d6e8e91ffb545c99e
Branch: agent/fix-526
Worktree: external/pulp-ara-526 (attached to this chat)
OpenSpec: openspec/changes/fix-vrgather-vi-uimm
Evidence/report: docs/issues/526/report.md
PR: https://github.com/yenhao-huang/ara/pull/1 (OPEN, draft; base main, head agent/fix-526)
Implementation commit: e708ec64cb3914d261cd4b6cf7b16ac1db4a7c0c

| Stage | Status | Evidence |
| --- | --- | --- |
| Issue | completed | Open; no comments or timeline entries; reporter patch read |
| Worktree | completed | Git worktree created and app attachment verified |
| Plan | completed | OpenSpec change validates with CLI 1.6.0 |
| Dev | completed | Two-line OPIVI gather override, C regressions, RTL harness and reference entry point |
| Test | blocked | Real RTL: baseline 32/128 failed, fixed 128/128 passed; C compiled; QEMU case 7 passed at VLEN 128/512/1024. Full SoC check unrun; full model/dependencies absent |
| PR | completed | Fork-only draft PR 1 read back; remote branch SHA verified with git ls-remote |

Environment: Windows host, dedicated Debian 12 Docker container ara526-dev. GitHub access works outside the restricted command sandbox. Initial App create_worktree call did not return; fallback Git worktree creation and attach_worktree succeeded.

Validation commands and excerpts: docs/issues/526/report.md. Verilator 5.006, Clang/LLD 14.0.6, QEMU 7.2.22. Raw logs and generated models are ignored under hardware/build/. No upstream writes. Full integration acceptance remains incomplete until the original reproducer / existing gather suite runs on Ara.

Delivery: branch and fork draft PR both exist. CI API returns no checks/runs and zero registered workflows on this fork, so no CI success is claimed. The worktree is retained for review. Next action is full Ara SoC regression in a complete environment; do not mark integration acceptance complete or merge based only on these focused results.
