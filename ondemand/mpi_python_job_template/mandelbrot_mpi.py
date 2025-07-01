#!/usr/bin/env python3
"""
MPI Mandelbrot Set Calculation
Optimized for HPC Toolset Tutorial Environment

This script calculates the Mandelbrot set using MPI for parallel processing.
It's designed to work with the current Slurm/OnDemand environment.
"""

import sys
import os
from datetime import datetime
import numpy as np

# Check if mpi4py is available, install if needed
try:
    from mpi4py import MPI
except ImportError:
    print("mpi4py not found, installing...")
    os.system("pip install --user mpi4py")
    from mpi4py import MPI

try:
    import matplotlib
    matplotlib.use('Agg')  # Use non-interactive backend
    import matplotlib.pyplot as plt
except ImportError:
    print("matplotlib not found, installing...")
    os.system("pip install --user matplotlib")
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

def log_print(*args, **kwargs):
    """Print with timestamp and rank information"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    rank = MPI.COMM_WORLD.Get_rank()
    print(f"[{now}] [Rank {rank}]", *args, **kwargs)
    sys.stdout.flush()

def mandelbrot(c, max_iter):
    """Calculate Mandelbrot iteration count for a complex number"""
    z = 0
    n = 0
    while abs(z) <= 2 and n < max_iter:
        z = z ** 2 + c
        n += 1
    return n

def mandelbrot_row(y, x_values, max_iter):
    """Calculate Mandelbrot values for an entire row"""
    return [mandelbrot(complex(x, y), max_iter) for x in x_values]

def plot_mandelbrot(xmin, xmax, ymin, ymax, width, height, max_iter, filename):
    """Main function to calculate and plot Mandelbrot set using MPI"""
    
    # Initialize MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    log_print(f"MPI initialized - Size: {size}, Rank: {rank}")
    log_print(f"Hostname: {os.uname().nodename}")
    log_print(f"Process ID: {os.getpid()}")
    
    # Create coordinate arrays
    x_values = np.linspace(xmin, xmax, width)
    y_values = np.linspace(ymin, ymax, height)
    
    log_print(f"Computing Mandelbrot set: {width}x{height}, max_iter={max_iter}")
    log_print(f"Domain: x=[{xmin}, {xmax}], y=[{ymin}, {ymax}]")
    
    # Distribute work using round-robin
    local_y_indices = list(range(rank, len(y_values), size))
    local_y = [y_values[i] for i in local_y_indices]
    
    log_print(f"Processing {len(local_y)} rows out of {len(y_values)} total rows")
    log_print(f"Row indices: {local_y_indices[:5]}{'...' if len(local_y_indices) > 5 else ''}")
    
    # Calculate local results
    start_time = datetime.now()
    log_print("Starting computation...")
    
    local_result = []
    for i, y in enumerate(local_y):
        if i % max(1, len(local_y) // 10) == 0:  # Progress every 10%
            progress = (i / len(local_y)) * 100
            log_print(f"Progress: {progress:.1f}%")
        
        row_result = mandelbrot_row(y, x_values, max_iter)
        local_result.append(row_result)
    
    computation_time = (datetime.now() - start_time).total_seconds()
    log_print(f"Local computation completed in {computation_time:.2f} seconds")
    
    # Gather results at root process
    log_print("Gathering results...")
    gather_start = datetime.now()
    
    all_results = comm.gather(local_result, root=0)
    all_indices = comm.gather(local_y_indices, root=0)
    
    gather_time = (datetime.now() - gather_start).total_seconds()
    log_print(f"Gather completed in {gather_time:.2f} seconds")
    
    # Root process assembles and saves the result
    if rank == 0:
        log_print("Assembling final result...")
        assembly_start = datetime.now()
        
        # Create full result array
        full_result = np.zeros((height, width))
        
        # Fill in results from all processes
        for proc_results, proc_indices in zip(all_results, all_indices):
            for local_idx, global_idx in enumerate(proc_indices):
                if local_idx < len(proc_results):
                    full_result[global_idx] = proc_results[local_idx]
        
        assembly_time = (datetime.now() - assembly_start).total_seconds()
        log_print(f"Assembly completed in {assembly_time:.2f} seconds")
        
        # Create and save plot
        log_print("Creating plot...")
        plot_start = datetime.now()
        
        plt.figure(figsize=(12, 12))
        plt.imshow(full_result, extent=(xmin, xmax, ymin, ymax), 
                  cmap='hot', origin='lower', interpolation='bilinear')
        plt.colorbar(label='Iterations')
        plt.title(f"Mandelbrot Set (MPI: {size} processes)\n"
                 f"Resolution: {width}x{height}, Max Iterations: {max_iter}")
        plt.xlabel("Real")
        plt.ylabel("Imaginary")
        
        # Add computation info
        total_time = computation_time + gather_time + assembly_time
        plt.figtext(0.02, 0.02, 
                   f"Computation: {computation_time:.2f}s, "
                   f"Gather: {gather_time:.2f}s, "
                   f"Assembly: {assembly_time:.2f}s, "
                   f"Total: {total_time:.2f}s",
                   fontsize=8, ha='left')
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        plt.close()
        
        plot_time = (datetime.now() - plot_start).total_seconds()
        log_print(f"Plot saved to {filename} in {plot_time:.2f} seconds")
        
        # Print summary
        total_pixels = width * height
        pixels_per_second = total_pixels / total_time
        log_print("=== COMPUTATION SUMMARY ===")
        log_print(f"Total pixels: {total_pixels:,}")
        log_print(f"MPI processes: {size}")
        log_print(f"Total time: {total_time:.2f} seconds")
        log_print(f"Performance: {pixels_per_second:,.0f} pixels/second")
        log_print(f"Output file: {filename}")
        log_print("=== COMPUTATION COMPLETE ===")
        
        # Verify file was created
        if os.path.exists(filename):
            file_size = os.path.getsize(filename)
            log_print(f"Output file size: {file_size:,} bytes")
        else:
            log_print("ERROR: Output file was not created!")
    
    # Synchronize all processes before exit
    comm.Barrier()
    log_print("Process finished")

if __name__ == "__main__":
    # Default parameters - can be modified for different resolutions/quality
    plot_mandelbrot(
        xmin=-2.0, xmax=1.0,      # Real axis range
        ymin=-1.5, ymax=1.5,      # Imaginary axis range  
        width=8000,               # Reduced from 10000 for faster computation
        height=8000,              # Reduced from 10000 for faster computation
        max_iter=1000,            # Maximum iterations
        filename='mandelbrot_mpi.png'
    )
