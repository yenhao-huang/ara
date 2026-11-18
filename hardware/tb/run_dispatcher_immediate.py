#!/usr/bin/env python3
"""Run the real dispatcher with Verilator; requires the Bender.lock dependencies.

Usage: python3 hardware/tb/run_dispatcher_immediate.py [--dispatcher PATH]
An alternate dispatcher source permits before/after testing with identical tests.
Generated files stay in hardware/build/dispatcher-immediate.
"""
# SPDX-License-Identifier: SHL-0.51
import argparse
import pathlib
import subprocess


def main():
    root = pathlib.Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dispatcher", type=pathlib.Path,
                        default=root / "hardware/src/ara_dispatcher.sv")
    parser.add_argument("--build-dir", type=pathlib.Path,
                        default=root / "hardware/build/dispatcher-immediate")
    args = parser.parse_args()
    build = args.build_dir.resolve()
    build.mkdir(parents=True, exist_ok=True)
    deps = root / "hardware/deps"
    cva6 = deps / "cva6/core/include"

    # Reuse the exact backend interface types from ara.sv, avoiding a second
    # hand-maintained copy. No production RTL is transformed or replaced.
    ara = (root / "hardware/src/ara.sv").read_text()
    begin = ara.index("  typedef struct packed {", ara.index("// Interfaces between"))
    end = ara.index("  } ara_resp_t;", begin) + len("  } ara_resp_t;")
    types = build / "ara_dispatcher_test_pkg.sv"
    types.write_text("""// Generated from hardware/src/ara.sv (SHL-0.51).
package ara_dispatcher_test_pkg;
  import ara_pkg::*;
  localparam int VLEN = 512;
  typedef logic [$clog2(VLEN+1)-1:0] vlen_t;
  localparam config_pkg::cva6_cfg_t Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
  `include "ara/intf_typedef.svh"
  `CVA6_TYPEDEF_EXCEPTION(exception_t, Cfg)
  `CVA6_INTF_TYPEDEF_ACC_REQ(accelerator_req_t, Cfg, fpnew_pkg::roundmode_e)
  `CVA6_INTF_TYPEDEF_ACC_RESP(accelerator_resp_t, Cfg, exception_t)
""" + ara[begin:end] + "\nendpackage\n")
    sources = [
        deps / "common_cells/src/cf_math_pkg.sv",
        cva6 / "config_pkg.sv",
        cva6 / "cv64a6_imafdcv_sv39_config_pkg.sv",
        cva6 / "build_config_pkg.sv",
        cva6 / "riscv_pkg.sv",
        deps / "axi/src/axi_pkg.sv",
        deps / "fpnew/src/fpnew_pkg.sv",
        root / "hardware/include/rvv_pkg.sv",
        root / "hardware/include/ara_pkg.sv",
        types,
        deps / "common_cells/src/popcount.sv",
        deps / "common_cells/src/counter.sv",
        deps / "common_cells/src/delta_counter.sv",
        root / "hardware/src/segment_sequencer.sv",
        args.dispatcher.resolve(),
        root / "hardware/tb/ara_dispatcher_immediate_tb.sv",
    ]
    for source in sources:
        if not source.is_file():
            parser.error(f"Missing {source}; check out hardware dependencies first")
    command = ["verilator", "--binary", "--timing", "--assert", "-Wno-fatal",
               "--top-module", "ara_dispatcher_immediate_tb", "-j", "2",
               "--Mdir", str(build),
               "-I" + str(root / "hardware/include"),
               "-I" + str(deps / "common_cells/include"),
               *map(str, sources)]
    subprocess.run(command, cwd=root, check=True)
    subprocess.run([str(build / "Vara_dispatcher_immediate_tb")], cwd=root, check=True)


if __name__ == "__main__":
    main()
