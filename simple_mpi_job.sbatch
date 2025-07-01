#!/bin/bash

#SBATCH --job-name=mpi_test
#SBATCH --output=mpi_test_%j.log
#SBATCH --error=mpi_test_%j.err
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:10:00

echo "=== MPI Test Job Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "Tasks: $SLURM_NTASKS"
echo "Node list: $SLURM_JOB_NODELIST"
echo "=========================="

# Set up MPI environment
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0

# Change to job directory
cd $SLURM_SUBMIT_DIR

# Install mpi4py if needed
/usr/bin/python3 -m pip install --user mpi4py

# Create a simple MPI test script
cat > mpi_hello.py << 'EOF'
#!/usr/bin/env python3
from mpi4py import MPI
import os

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = os.uname().nodename

print(f"Hello from rank {rank} of {size} processes on node {hostname}")

if rank == 0:
    print("✓ MPI test completed successfully!")
EOF

# Run the MPI test
echo "Running MPI test with $SLURM_NTASKS processes..."
mpirun -np $SLURM_NTASKS /usr/bin/python3 mpi_hello.py

echo "=== MPI Test Job Completed ==="
