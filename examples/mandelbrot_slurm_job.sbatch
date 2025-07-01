#!/bin/bash

#SBATCH --job-name=mandelbrot_mpi
#SBATCH --output=mandelbrot_output_%j.log
#SBATCH --error=mandelbrot_error_%j.log
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=02:00:00
#SBATCH --partition=compute

# Mandelbrot Set MPI Calculation Job
# This job runs your MPI Python script across multiple nodes

echo "=========================================="
echo "Mandelbrot MPI Job Started"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "Total Tasks: $SLURM_NTASKS"
echo "Tasks per Node: $SLURM_NTASKS_PER_NODE"
echo "CPUs per Task: $SLURM_CPUS_PER_TASK"
echo "Memory per CPU: ${SLURM_MEM_PER_CPU}MB"
echo "Time Limit: $SLURM_TIMELIMIT"
echo "Working Directory: $SLURM_SUBMIT_DIR"
echo "Node List: $SLURM_JOB_NODELIST"
echo "=========================================="

# Change to submission directory
cd $SLURM_SUBMIT_DIR

# Set up MPI environment
echo "Setting up MPI environment..."
export PATH="/usr/lib64/openmpi/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"
export MPI_ROOT="/usr/lib64/openmpi"

# MPI optimization for container environment
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=ssh
export OMPI_MCA_btl_tcp_if_include=eth0

# Activate Python environment
echo "Activating Python environment..."
if [ -d "/usr/local/jupyter/4.3.5" ]; then
    source /usr/local/jupyter/4.3.5/bin/activate
    echo "✓ Jupyter environment activated"
else
    echo "⚠ Jupyter environment not found, using system Python"
fi

# Install required packages if not present
echo "Checking Python dependencies..."
python3 -c "import mpi4py" 2>/dev/null || {
    echo "Installing mpi4py..."
    pip install --user mpi4py
}

python3 -c "import numpy" 2>/dev/null || {
    echo "Installing numpy..."
    pip install --user numpy
}

python3 -c "import matplotlib" 2>/dev/null || {
    echo "Installing matplotlib..."
    pip install --user matplotlib
}

# Verify MPI setup
echo "Verifying MPI setup..."
echo "MPI Version: $(mpirun --version | head -1)"
echo "Python MPI: $(python3 -c 'from mpi4py import MPI; print(f"✓ MPI.COMM_WORLD.Get_size() available")')"

# Create the Mandelbrot script if it doesn't exist
if [ ! -f "mandelbrot_mpi.py" ]; then
    echo "Creating Mandelbrot MPI script..."
    cat > mandelbrot_mpi.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
MPI Mandelbrot Set Calculation - Optimized for Slurm
"""

import sys
import os
from datetime import datetime
import numpy as np

try:
    from mpi4py import MPI
except ImportError:
    print("Installing mpi4py...")
    os.system("pip install --user mpi4py")
    from mpi4py import MPI

try:
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt
except ImportError:
    print("Installing matplotlib...")
    os.system("pip install --user matplotlib")
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

def plot_mandelbrot(xmin, xmax, ymin, ymax, width, height, max_iter, filename):
    """Main MPI Mandelbrot calculation"""
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    log_print(f"Starting Mandelbrot calculation")
    log_print(f"MPI Size: {size}, Resolution: {width}x{height}, Max Iter: {max_iter}")
    
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
        plt.figure(figsize=(12, 12))
        plt.imshow(full_result, extent=(xmin, xmax, ymin, ymax), 
                  cmap='hot', origin='lower')
        plt.colorbar(label='Iterations')
        plt.title(f"Mandelbrot Set (MPI: {size} processes)\n"
                 f"Resolution: {width}x{height}, Max Iterations: {max_iter}")
        plt.xlabel("Real")
        plt.ylabel("Imaginary")
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
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
    # Adjust resolution based on available time/resources
    plot_mandelbrot(
        xmin=-2.0, xmax=1.0,
        ymin=-1.5, ymax=1.5,
        width=6000,   # Reasonable resolution for demo
        height=6000,
        max_iter=1000,
        filename='mandelbrot_mpi_result.png'
    )
PYTHON_SCRIPT
    
    echo "✓ Mandelbrot script created"
fi

# Display job environment
echo "=========================================="
echo "Job Environment:"
echo "Python: $(python3 --version)"
echo "MPI: $(mpirun --version | head -1)"
echo "NumPy: $(python3 -c 'import numpy; print(numpy.__version__)')"
echo "Matplotlib: $(python3 -c 'import matplotlib; print(matplotlib.__version__)')"
echo "Working Dir: $(pwd)"
echo "Available files: $(ls -la *.py 2>/dev/null || echo 'No Python files')"
echo "=========================================="

# Run the MPI job
echo "Starting MPI Mandelbrot calculation..."
echo "Command: mpirun -np $SLURM_NTASKS python3 mandelbrot_mpi.py"
echo

# Execute the MPI job
mpirun -np $SLURM_NTASKS python3 mandelbrot_mpi.py

# Check results
echo
echo "=========================================="
echo "Job Results:"
if [ -f "mandelbrot_mpi_result.png" ]; then
    echo "✓ Output image created: mandelbrot_mpi_result.png"
    echo "  Size: $(ls -lh mandelbrot_mpi_result.png | awk '{print $5}')"
else
    echo "✗ Output image not found"
fi

echo "Log files:"
echo "  Output: mandelbrot_output_${SLURM_JOB_ID}.log"
echo "  Error:  mandelbrot_error_${SLURM_JOB_ID}.log"
echo "=========================================="
echo "Mandelbrot MPI Job Completed at: $(date)"
echo "=========================================="
