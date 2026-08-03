# systemVerilog_code
Repository to prepare for Mixed signal verification roles.

## Structure
- [accumulator/rtl/accumulator.svh](accumulator/rtl/accumulator.svh)
- [accumulator/tb/accumulator_tb.sv](accumulator/tb/accumulator_tb.sv)

## Simulation
Each project keeps its own Makefile inside its directory.

From the repository root you can run the commands for all projects:

- `make build` to build all projects
- `make run` to run all projects
- `make wave` to open waveforms for all projects
- `make clean` to clean all projects

To work on a single project, go into its folder and run its local Makefile, for example:

- `make -C accumulator build`
- `make -C accumulator run`

For the accumulator project, there are two testbenches:

- unsigned accumulator: `make -C accumulator run`
- signed accumulator: `make -C accumulator signed`

You can also build only the signed testbench with:

- `make -C accumulator signed-build`
