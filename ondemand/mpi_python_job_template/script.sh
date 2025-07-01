#!/bin/bash

#SBATCH --job-name=mpi_python_job
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --output=mpi_output_%j.log
#SBATCH --error=mpi_error_%j.log

# MPI Python Job Template for Mandelbrot Set Calculation

echo "=== MPI Python Job Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "Tasks: $SLURM_NTASKS"
echo "Tasks per node: $SLURM_NTASKS_PER_NODE"
echo "CPUs per task: $SLURM_CPUS_PER_TASK"
echo "Working directory: $SLURM_SUBMIT_DIR"
echo "Node list: $SLURM_JOB_NODELIST"
echo "================================"

# Set up Python environment
echo "Setting up Python environment..."
source /usr/local/jupyter/4.3.5/bin/activate

# Install required packages if not already installed
echo "Installing required Python packages..."
pip install --user mpi4py numpy matplotlib

# Move to the directory where the job was submitted from
cd $SLURM_SUBMIT_DIR

# Set MPI environment variables
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0

# Print MPI information
echo "MPI Configuration:"
echo "SLURM_PROCID: $SLURM_PROCID"
echo "SLURM_LOCALID: $SLURM_LOCALID"
echo "SLURM_NODEID: $SLURM_NODEID"

# Run the MPI Python script
echo "Starting MPI Python execution..."
echo "Command: mpirun -np $SLURM_NTASKS python mandelbrot_mpi.py"

# Execute the MPI Python script
mpirun -np $SLURM_NTASKS python mandelbrot_mpi.py

# Check exit status
if [ $? -eq 0 ]; then
    echo "=== MPI Python Job Completed Successfully ==="
    echo "Output files should be available in: $SLURM_SUBMIT_DIR"
    ls -la *.png *.log 2>/dev/null || echo "No output files found"
else
    echo "=== MPI Python Job Failed ==="
    echo "Check error log: mpi_error_${SLURM_JOB_ID}.log"
fi

echo "Job finished at: $(date)"
