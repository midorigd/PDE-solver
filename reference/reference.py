import numpy as np
import matplotlib.pyplot as plt
import argparse

def solve_laplace_jacobi(N=64, max_iters=1000, tol=1e-4, top=1.0, bot=0.0, left=0.0, right=0.0):
    """
    Solve Laplace's equation on an NxN grid using Jacobi iteration.
    """
    u = np.zeros((N, N))

    u[:, 0]  = left
    u[:, -1] = right
    u[-1, :] = bot
    u[0, :]  = top

    for iteration in range(max_iters):
        u_old = u.copy()

        u[1:-1, 1:-1] = 0.25 * (
            u_old[0:-2, 1:-1] +
            u_old[2:,   1:-1] +
            u_old[1:-1, 0:-2] +
            u_old[1:-1, 2:  ]
        )

        u[:, 0]  = left
        u[:, -1] = right
        u[-1, :] = bot
        u[0, :]  = top

        delta = np.max(np.abs(u - u_old))
        if delta < tol:
            print(f"Converged after {iteration+1} iterations (delta={delta:.2e})")
            break
    else:
        print(f"Did not converge after {max_iters} iterations")

    return u


def to_fixed(val, fmt):
    if fmt == 'q8':
        return int(round(val * 256)) & 0xFFFF, 4
    elif fmt == 'q16':
        return int(round(val * 65536)) & 0xFFFFFFFF, 8
    else:
        raise ValueError(f"Unknown format: {fmt}. Use 'q8' or 'q16'.")


def main():
    parser = argparse.ArgumentParser(description="Jacobi solver reference for FPGA verification")

    parser.add_argument('--N',        type=int,   default=32,      help='Grid dimension (default: 32)')
    parser.add_argument('--iters',    type=int,   default=1000,    help='Max iterations (default: 1000)')
    parser.add_argument('--tol',      type=float, default=1e-4,    help='Convergence tolerance (default: 1e-4)')
    parser.add_argument('--fmt',      type=str,   default='q8',    help='Fixed-point format: q8 or q16 (default: q8)')
    parser.add_argument('--top',      type=float, default=1.0,     help='Top boundary value (default: 1.0)')
    parser.add_argument('--bot',      type=float, default=0.0,     help='Bottom boundary value (default: 0.0)')
    parser.add_argument('--left',     type=float, default=0.0,     help='Left boundary value (default: 0.0)')
    parser.add_argument('--right',    type=float, default=0.0,     help='Right boundary value (default: 0.0)')
    parser.add_argument('--out',      type=str,   default='hardware/reference.hex', help='Output hex file path')
    parser.add_argument('--plot',     action='store_true',          help='Show and save solution plot')
    parser.add_argument('--plot-out', type=str,   default='reference/laplace_solution_test.png', help='Plot output path')

    args = parser.parse_args()

    u = solve_laplace_jacobi(
        N=args.N,
        max_iters=args.iters,
        tol=args.tol,
        top=args.top,
        bot=args.bot,
        left=args.left,
        right=args.right
    )

    with open(args.out, 'w') as f:
        for val in u.flatten():
            fixed, width = to_fixed(val, args.fmt)
            f.write(f'{fixed:0{width}x}\n')

    print(f"Wrote {args.N*args.N} values to {args.out} ({args.fmt})")

    if args.plot:
        plt.figure(figsize=(6, 5))
        plt.imshow(u, origin='upper', cmap='hot', interpolation='bilinear')
        plt.colorbar(label='u')
        plt.title(f"2D Laplace — Jacobi ({args.N}x{args.N}, {args.fmt})")
        plt.xlabel("x")
        plt.ylabel("y")
        plt.tight_layout()
        plt.savefig(args.plot_out, dpi=150)
        print(f"Saved plot to {args.plot_out}")
        plt.show()


if __name__ == '__main__':
    main()
