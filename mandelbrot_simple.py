#!/usr/bin/env python3
"""
Simplified Mandelbrot MPI calculation for testing
"""

import sys
import os
from datetime import datetime
import numpy as np

# Try to import MPI, install if needed
try:
    from mpi4py import MPI
except ImportError:
    print("Installing mpi4py...")
    os.system("/usr/bin/python3 -m pip install --user mpi4py")
    from mpi4py import MPI

# Try to import matplotlib, install if needed
try:
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt
except ImportError:
    print("Installing matplotlib...")
    os.system("/usr/bin/python3 -m pip install --user matplotlib")
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

def log_print(*args, **kwargs):
    """Print with timestamp and rank"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    rank = MPI.COMM_WORLD.Get_rank()
    hostname = os.uname().nodename
    print(f"[{now}] [Rank {rank}@{hostname}]", *args, **kwargs)
    sys.stdout.flush()

def mandelbrot(c, max_iter):
    """Calculate Mandelbrot iteration count"""
    z = 0
    n = 0
    while abs(z) <= 2 and n < max_iter:
        z = z ** 2 + c
        n += 1
    return n

def mandelbrot_row(y, x_values, max_iter):
    """Calculate Mandelbrot values for a row"""
    return [mandelbrot(complex(x, y), max_iter) for x in x_values]

def main():
    """Main MPI Mandelbrot calculation"""
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    log_print(f"Starting Mandelbrot calculation")
    log_print(f"MPI Size: {size}")
    
    # Small test parameters for quick execution
    xmin, xmax = -2.0, 1.0
    ymin, ymax = -1.5, 1.5
    width, height = 1000, 1000  # Small resolution for testing
    max_iter = 100
    
    # Create coordinate arrays
    x_values = np.linspace(xmin, xmax, width)
    y_values = np.linspace(ymin, ymax, height)
    
    # Distribute work
    local_y_indices = list(range(rank, len(y_values), size))
    local_y = [y_values[i] for i in local_y_indices]
    
    log_print(f"Processing {len(local_y)} rows")
    
    # Calculate local results
    start_time = datetime.now()
    local_result = []
    
    for i, y in enumerate(local_y):
        if i % max(1, len(local_y) // 5) == 0:
            progress = (i / len(local_y)) * 100
            log_print(f"Progress: {progress:.1f}%")
        
        row_result = mandelbrot_row(y, x_values, max_iter)
        local_result.append(row_result)
    
    calc_time = (datetime.now() - start_time).total_seconds()
    log_print(f"Local calculation completed in {calc_time:.2f}s")
    
    # Gather results
    log_print("Gathering results...")
    all_results = comm.gather(local_result, root=0)
    all_indices = comm.gather(local_y_indices, root=0)
    
    # Root process creates the image
    if rank == 0:
        log_print("Assembling final image...")
        
        # Create result array
        full_result = np.zeros((height, width))
        
        # Fill results
        for proc_results, proc_indices in zip(all_results, all_indices):
            for local_idx, global_idx in enumerate(proc_indices):
                if local_idx < len(proc_results):
                    full_result[global_idx] = proc_results[local_idx]
        
        # Create plot
        plt.figure(figsize=(8, 8))
        plt.imshow(full_result, extent=(xmin, xmax, ymin, ymax), 
                  cmap='hot', origin='lower')
        plt.colorbar(label='Iterations')
        plt.title(f"Mandelbrot Set (MPI: {size} processes)\n"
                 f"Resolution: {width}x{height}, Max Iterations: {max_iter}")
        plt.xlabel("Real")
        plt.ylabel("Imaginary")
        
        filename = 'mandelbrot_mpi_test.png'
        plt.tight_layout()
        plt.savefig(filename, dpi=150, bbox_inches='tight')
        plt.close()
        
        log_print(f"Image saved to {filename}")
        
        # Print summary
        total_pixels = width * height
        log_print("=== SUMMARY ===")
        log_print(f"Total pixels: {total_pixels:,}")
        log_print(f"MPI processes: {size}")
        log_print(f"Calculation time: {calc_time:.2f}s")
        log_print(f"Output: {filename}")
        
        if os.path.exists(filename):
            size_mb = os.path.getsize(filename) / (1024*1024)
            log_print(f"File size: {size_mb:.2f} MB")
    
    comm.Barrier()
    log_print("Process finished")

if __name__ == "__main__":
    main()
