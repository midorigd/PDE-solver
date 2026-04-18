# FPGA 2D Laplace Equation Solver

A fully parametrized hardware implementation of a 2D Laplace equation solver using Jacobi iteration, written in Verilog and targeting FPGA synthesis. The design includes a complete RTL pipeline from boundary condition initialization through iterative stencil computation to convergence detection, verified against a floating-point Python reference.

---

## Background

### The Problem

Laplace's equation describes steady-state phenomena across physics and engineering — electrostatic potential, heat distribution, fluid flow, and more. In 2D:

$$\frac{\partial^2 u}{\partial x^2} + \frac{\partial^2 u}{\partial y^2} = 0$$

Given fixed values on the boundary of a domain (e.g. a square plate with each edge held at a fixed voltage), the equation determines the equilibrium value at every interior point.

### Numerical Method

The continuous domain is discretized onto an N×N grid using second-order central finite differences, reducing the PDE to a system of linear equations. Each interior point satisfies:

$$u[i][j] = \frac{1}{4}\left(u[i-1][j] + u[i+1][j] + u[i][j-1] + u[i][j+1]\right)$$

**Jacobi iteration** solves this system by repeatedly applying this stencil to every interior point simultaneously, reading from the previous iteration's values and writing to a new buffer. The method converges when the maximum pointwise change across the grid falls below a threshold ε.

Jacobi's fully parallel update rule — every point is independent within a single sweep — makes it particularly well-suited to hardware implementation.

### Hardware vs. Software

A software Jacobi solver is straightforward but memory-bandwidth-bound. An FPGA implementation can exploit the structure of the problem directly in silicon: the stencil operation is a fixed computation, the memory access pattern is deterministic, and the iterative structure maps cleanly to a finite state machine. This makes it a compelling case study in hardware acceleration of numerical workloads.

## Architecture

### Module Hierarchy

```
PDEsolver (top)
├── init          — boundary condition initialization FSM
├── bram (×2)     — ping-pong grid buffers (BRAM_A, BRAM_B)
├── jacobi        — iteration control FSM
│   └── stencil   — combinational stencil compute unit
```

### Key Design Decisions

**Ping-pong buffering:** Jacobi requires reading the old grid while writing the new one. Two BRAMs swap roles each iteration controlled by a single `bufSel` bit, eliminating read-write conflicts with no additional logic overhead.

**Fixed-point arithmetic:** Floating point is area-expensive in FPGA fabric. The design uses parametrized Qn.n fixed-point (Q8.8 by default, Q16.16 supported) throughout. The stencil divide-by-4 reduces to a 2-bit right shift, exact and inexpensive in hardware.

**Combinational stencil unit:** The compute unit is purely combinational with no registers, keeping it outside the FSM and ensuring `u_new` and `delta` are always valid once the five neighbor values are latched. This separates datapath from control cleanly.

**Combinational BRAM routing:** Buffer selection, write enables, and address/data routing are all continuous assignments driven by `bufSel` and FSM state. This keeps the sequential always block focused on control flow and avoids unintended register inference.

**Convergence detection:** The FSM tracks the running maximum absolute delta across each full sweep using fixed-point two's complement absolute value. Iteration halts when max delta falls below ε or the iteration limit is reached.

### FSM States

| State | Description |
|-------|-------------|
| `IDLE` | Waiting for start signal |
| `READ` | Sequential neighbor reads with BRAM latency compensation (7 cycles) |
| `COMPUTE` | Update max delta from stencil output |
| `WRITE` | Assert write enable; data routing handled combinationally |
| `NEXT_POINT` | Advance grid coordinates, detect sweep completion |
| `CHECK_CONV` | Compare max delta to epsilon, decide continue or halt |
| `NEXT_ITER` | Flip buffer, reset sweep state, increment iteration counter |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Grid dimension (N×N), must be power of 2 |
| `DATA_WIDTH` | 16 | Fixed-point word width (16 = Q8.8, 32 = Q16.16) |
| `MAX_ITERS` | 1000 | Maximum iteration count |
| `EPSILON` | `16'h0001` | Convergence threshold in fixed-point |
| `TOP_VAL` | `16'h0100` | Top edge boundary value (1.0 in Q8.8) |
| `BOT_VAL` | `0` | Bottom edge boundary value |
| `LEFT_VAL` | `0` | Left edge boundary value |
| `RIGHT_VAL` | `0` | Right edge boundary value |

All parameters propagate from the top-level module, so reconfiguring the solver requires no changes to RTL source files.

## Verification

### Methodology

A Python reference solver using NumPy implements the identical Jacobi scheme in 64-bit floating point. The reference outputs a hex file in the target fixed-point format which the Verilog testbench loads via `$readmemh` for direct comparison.

Tests are run to convergence and compared within a per-scale tolerance that accounts for accumulated fixed-point rounding error.

### Test Matrix

| N | Q8.8 | Q16.16 |
|---|--------|--------|
| 8 | Pass | Pass |
| 16 | Pass | Pass |
| 32 | Pass | Pass |
| 64 | Pass | Pass |

### Running Tests

Generate the Python reference (COMING SOON):

```bash
python3 reference.py --N 8 --iters 10 --format q8
```

Compile and simulate:

```bash
iverilog -o sim.vvp tb.v
vvp sim.vvp
```

## File Structure

```
├── bram.v          — parametrized synchronous BRAM (read-first)
├── stencil.v       — combinational stencil + absolute delta
├── init.v          — boundary initialization FSM
├── jacobi.v        — Jacobi iteration FSM
├── PDEsolver.v     — top-level integration
├── tb.v            — testbench with BRAM readback and comparison
└── reference.py    — Python floating-point reference solver
```

## Skills

- RTL design in Verilog — FSMs, parametrized modules, synchronous BRAM inference
- Fixed-point arithmetic — format selection, overflow analysis, precision tradeoffs
- Hardware/software co-verification — matching numerical behavior between fixed-point RTL and floating-point reference
- FPGA-oriented design patterns — ping-pong buffering, BRAM latency compensation, combinational vs registered signal discipline
- Numerical methods — finite difference discretization, iterative solvers, convergence analysis
