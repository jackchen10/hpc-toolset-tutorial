#!/bin/bash

#SBATCH --job-name=mandelbrot_single
#SBATCH --output=mandelbrot_single_%j.log
#SBATCH --error=mandelbrot_single_%j.err
#SBATCH --ntasks=2
#SBATCH --time=00:10:00

echo "=== Mandelbrot MPI Single Node Test ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "Tasks: $SLURM_NTASKS"
echo "Node list: $SLURM_JOB_NODELIST"
echo "=================================="

# Change to job directory
cd $SLURM_SUBMIT_DIR

# Set up MPI environment
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0

# Install dependencies
echo "Installing Python dependencies..."
/usr/bin/python3 -m pip install --user mpi4py numpy matplotlib

# Run the test
echo "Starting Mandelbrot MPI calculation..."
mpirun -np $SLURM_NTASKS /usr/bin/python3 mandelbrot_simple.py

echo "=== Test Completed ==="
