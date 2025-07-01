#!/bin/bash

#SBATCH --job-name=mandelbrot_test
#SBATCH --output=mandelbrot_test_%j.log
#SBATCH --error=mandelbrot_test_%j.err
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:15:00

echo "=== Mandelbrot MPI Test Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "Tasks: $SLURM_NTASKS"
echo "Node list: $SLURM_JOB_NODELIST"
echo "Working directory: $SLURM_SUBMIT_DIR"
echo "=================================="

# Change to job directory
cd $SLURM_SUBMIT_DIR

# Set up MPI environment
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=ssh

# Check MPI installation
echo "Checking MPI installation..."
which mpirun
mpirun --version | head -1

# Check Python and install dependencies
echo "Checking Python and dependencies..."
/usr/bin/python3 --version
/usr/bin/python3 -m pip install --user mpi4py numpy matplotlib

# Run the Mandelbrot MPI test
echo "Starting Mandelbrot MPI calculation..."
echo "Command: mpirun -np $SLURM_NTASKS /usr/bin/python3 mandelbrot_simple.py"

mpirun -np $SLURM_NTASKS /usr/bin/python3 mandelbrot_simple.py

# Check results
echo "=================================="
echo "Job Results:"
if [ -f "mandelbrot_mpi_test.png" ]; then
    echo "✓ Output image created: mandelbrot_mpi_test.png"
    echo "  Size: $(ls -lh mandelbrot_mpi_test.png | awk '{print $5}')"
else
    echo "✗ Output image not found"
fi

echo "Log files:"
echo "  Output: mandelbrot_test_${SLURM_JOB_ID}.log"
echo "  Error:  mandelbrot_test_${SLURM_JOB_ID}.err"
echo "=================================="
echo "Mandelbrot MPI Test Completed at: $(date)"
