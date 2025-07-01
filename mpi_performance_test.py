#!/usr/bin/env python3
"""
MPI Performance Test - Compare different process counts
"""

import os
import time
import socket
from datetime import datetime
from mpi4py import MPI
import numpy as np

def mandelbrot_simple(c, max_iter=100):
    """Simple Mandelbrot calculation"""
    z = 0
    n = 0
    while abs(z) <= 2 and n < max_iter:
        z = z ** 2 + c
        n += 1
    return n

def run_performance_test():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    hostname = socket.gethostname()
    
    # Test parameters
    width, height = 800, 600
    max_iter = 100
    
    # Calculate work distribution
    rows_per_process = height // size
    start_row = rank * rows_per_process
    end_row = start_row + rows_per_process
    if rank == size - 1:  # Last process takes remaining rows
        end_row = height
    
    if rank == 0:
        print(f"=== MPI Performance Test ===")
        print(f"Image size: {width}x{height}")
        print(f"Max iterations: {max_iter}")
        print(f"MPI processes: {size}")
        print(f"Rows per process: {rows_per_process}")
        print(f"Starting calculation...")
    
    # Synchronize start time
    comm.Barrier()
    start_time = time.time()
    
    # Calculate assigned rows
    local_data = []
    total_pixels = 0
    
    for y in range(start_row, end_row):
        row_data = []
        for x in range(width):
            # Map pixel to complex plane
            real = (x - width/2) * 4.0 / width
            imag = (y - height/2) * 4.0 / height
            c = complex(real, imag)
            
            # Calculate Mandelbrot value
            value = mandelbrot_simple(c, max_iter)
            row_data.append(value)
            total_pixels += 1
        
        local_data.append(row_data)
    
    # Calculate local time
    local_time = time.time() - start_time
    
    # Gather timing results
    all_times = comm.gather(local_time, root=0)
    all_pixels = comm.gather(total_pixels, root=0)
    all_hostnames = comm.gather(hostname, root=0)
    
    if rank == 0:
        total_time = time.time() - start_time
        total_pixel_count = sum(all_pixels)
        
        print(f"\n=== Performance Results ===")
        print(f"Total calculation time: {total_time:.3f}s")
        print(f"Total pixels calculated: {total_pixel_count:,}")
        print(f"Pixels per second: {total_pixel_count/total_time:,.0f}")
        
        print(f"\n=== Per-Process Breakdown ===")
        unique_hosts = set(all_hostnames)
        print(f"Unique nodes: {len(unique_hosts)} ({list(unique_hosts)})")
        
        for i in range(size):
            print(f"Rank {i}@{all_hostnames[i]}: {all_pixels[i]:,} pixels in {all_times[i]:.3f}s ({all_pixels[i]/all_times[i]:,.0f} pix/s)")
        
        # Calculate efficiency
        max_time = max(all_times)
        min_time = min(all_times)
        efficiency = min_time / max_time * 100
        
        print(f"\n=== Efficiency Analysis ===")
        print(f"Fastest process: {min_time:.3f}s")
        print(f"Slowest process: {max_time:.3f}s")
        print(f"Load balance efficiency: {efficiency:.1f}%")
        
        # Theoretical vs actual speedup
        if size > 1:
            sequential_estimate = total_pixel_count / (sum(all_pixels)/sum(all_times))
            actual_speedup = sequential_estimate / total_time
            theoretical_speedup = size
            parallel_efficiency = actual_speedup / theoretical_speedup * 100
            
            print(f"Estimated sequential time: {sequential_estimate:.3f}s")
            print(f"Actual speedup: {actual_speedup:.2f}x")
            print(f"Theoretical speedup: {theoretical_speedup}x")
            print(f"Parallel efficiency: {parallel_efficiency:.1f}%")

if __name__ == "__main__":
    run_performance_test()
