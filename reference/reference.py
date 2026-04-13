import numpy as np
import matplotlib.pyplot as plt

def solve_laplace_jacobi(N=50, max_iters=5000, tol=1e-4):
    """
    Solve Laplace's equation on an NxN grid using Jacobi iteration.
    Boundary conditions: 
      top = 1.0, bottom/left/right = 0.0
    """
    u = np.zeros((N, N))

    # Apply boundary conditions
    u[0, :]  = 1.0   # top edge
    u[-1, :] = 0.0   # bottom edge
    u[:, 0]  = 0.0   # left edge
    u[:, -1] = 0.0   # right edge

    for iteration in range(max_iters):
        u_old = u.copy()

        # Jacobi update: average of 4 neighbors (interior only)
        u[1:-1, 1:-1] = 0.25 * (
            u_old[0:-2, 1:-1] +   # above
            u_old[2:,   1:-1] +   # below
            u_old[1:-1, 0:-2] +   # left
            u_old[1:-1, 2:  ]     # right
        )

        # Re-enforce boundary conditions (defensive)
        u[0, :]  = 1.0
        u[-1, :] = 0.0
        u[:, 0]  = 0.0
        u[:, -1] = 0.0

        # Convergence check
        delta = np.max(np.abs(u - u_old))
        if delta < tol:
            print(f"Converged after {iteration+1} iterations (delta={delta:.2e})")
            break
    else:
        print(f"Did not converge after {max_iters} iterations")

    return u

# u = solve_laplace_jacobi(N=50)
u = solve_laplace_jacobi(N=8, max_iters=1000, tol=5/256)

with open('reference.hex', 'w') as f:
    for val in u.flatten():
        fixed = int(val * 256) & 0xFFFF
        f.write(f'{fixed:04x}\n')

plt.figure(figsize=(6, 5))
plt.imshow(u, origin='upper', cmap='hot', interpolation='bilinear')
plt.colorbar(label='u')
plt.title("2D Laplace — Jacobi Iteration")
plt.xlabel("x")
plt.ylabel("y")
plt.tight_layout()
plt.savefig("laplace_solution.png", dpi=150)
plt.show()
