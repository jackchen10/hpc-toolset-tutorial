#!/bin/bash

# Install MPI Support for HPC Toolset Tutorial
# This script adds MPI capabilities to the existing Slurm environment

set -e

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Starting MPI installation for HPC Toolset Tutorial..."

# Update package manager
log_info "Updating package manager..."
dnf update -y

# Install MPI packages
log_info "Installing OpenMPI and development tools..."
dnf install -y \
    openmpi \
    openmpi-devel \
    python3-mpi4py \
    python3-numpy \
    python3-matplotlib \
    environment-modules

# Install additional Python packages
log_info "Installing Python packages in Jupyter environment..."
if [ -d "/usr/local/jupyter/4.3.5" ]; then
    source /usr/local/jupyter/4.3.5/bin/activate
    pip install --upgrade pip
    pip install mpi4py numpy matplotlib scipy
    deactivate
    log_info "Python packages installed in Jupyter environment"
else
    log_info "Jupyter environment not found, installing system-wide..."
    python3 -m pip install --user mpi4py numpy matplotlib scipy
fi

# Set up MPI environment
log_info "Setting up MPI environment..."

# Create MPI module file
mkdir -p /usr/share/Modules/modulefiles/mpi
cat > /usr/share/Modules/modulefiles/mpi/openmpi << 'EOF'
#%Module1.0
##
## OpenMPI module file
##
proc ModulesHelp { } {
    puts stderr "This module loads OpenMPI"
}

module-whatis "OpenMPI parallel computing library"

set version 4.1.0
set root /usr/lib64/openmpi

prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib
prepend-path MANPATH $root/share/man
prepend-path PKG_CONFIG_PATH $root/lib/pkgconfig

setenv MPI_ROOT $root
setenv OMPI_MCA_btl_vader_single_copy_mechanism none
setenv OMPI_MCA_btl_base_warn_component_unused 0
EOF

# Add MPI paths to system environment
log_info "Configuring system MPI environment..."
cat > /etc/profile.d/mpi.sh << 'EOF'
# MPI Environment Configuration
export PATH="/usr/lib64/openmpi/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"
export MANPATH="/usr/lib64/openmpi/share/man:$MANPATH"
export MPI_ROOT="/usr/lib64/openmpi"

# MPI runtime optimizations for containers
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=ssh
export OMPI_MCA_btl_tcp_if_include=eth0
EOF

# Make the script executable
chmod +x /etc/profile.d/mpi.sh

# Update Slurm configuration for MPI support
log_info "Updating Slurm configuration for MPI..."
if [ -f "/etc/slurm/slurm.conf" ]; then
    # Backup original config
    cp /etc/slurm/slurm.conf /etc/slurm/slurm.conf.backup
    
    # Update MPI default
    sed -i 's/MpiDefault=none/MpiDefault=pmix/' /etc/slurm/slurm.conf
    
    log_info "Slurm configuration updated for MPI support"
else
    log_info "Slurm configuration not found, skipping update"
fi

# Create MPI test script
log_info "Creating MPI test script..."
cat > /usr/local/bin/test_mpi.py << 'EOF'
#!/usr/bin/env python3
"""
Simple MPI test script to verify installation
"""
try:
    from mpi4py import MPI
    import numpy as np
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    print(f"Hello from rank {rank} of {size} processes")
    
    if rank == 0:
        data = np.arange(10)
        print(f"Root process sending data: {data}")
    else:
        data = None
    
    data = comm.bcast(data, root=0)
    print(f"Rank {rank} received data: {data}")
    
    comm.Barrier()
    if rank == 0:
        print("MPI test completed successfully!")
        
except ImportError as e:
    print(f"MPI test failed: {e}")
    exit(1)
EOF

chmod +x /usr/local/bin/test_mpi.py

# Create MPI job submission helper
log_info "Creating MPI job submission helper..."
cat > /usr/local/bin/submit_mpi_job.sh << 'EOF'
#!/bin/bash

# MPI Job Submission Helper
# Usage: submit_mpi_job.sh <script.py> [nodes] [tasks_per_node]

SCRIPT=${1:-"mandelbrot_mpi.py"}
NODES=${2:-2}
TASKS_PER_NODE=${3:-2}
TOTAL_TASKS=$((NODES * TASKS_PER_NODE))

if [ ! -f "$SCRIPT" ]; then
    echo "Error: Script file '$SCRIPT' not found"
    exit 1
fi

echo "Submitting MPI job:"
echo "  Script: $SCRIPT"
echo "  Nodes: $NODES"
echo "  Tasks per node: $TASKS_PER_NODE"
echo "  Total tasks: $TOTAL_TASKS"

sbatch << EOF
#!/bin/bash
#SBATCH --job-name=mpi_$(basename $SCRIPT .py)
#SBATCH --nodes=$NODES
#SBATCH --ntasks=$TOTAL_TASKS
#SBATCH --ntasks-per-node=$TASKS_PER_NODE
#SBATCH --time=01:00:00
#SBATCH --output=mpi_output_%j.log
#SBATCH --error=mpi_error_%j.log

# Load MPI environment
source /etc/profile.d/mpi.sh

# Activate Python environment
source /usr/local/jupyter/4.3.5/bin/activate 2>/dev/null || true

echo "=== MPI Job Information ==="
echo "Job ID: \$SLURM_JOB_ID"
echo "Nodes: \$SLURM_JOB_NUM_NODES"
echo "Tasks: \$SLURM_NTASKS"
echo "Node list: \$SLURM_JOB_NODELIST"
echo "=========================="

# Run MPI job
mpirun -np \$SLURM_NTASKS python $SCRIPT

echo "Job completed at: \$(date)"
EOF

echo "Job submitted. Use 'squeue' to check status."
EOF

chmod +x /usr/local/bin/submit_mpi_job.sh

# Test MPI installation
log_info "Testing MPI installation..."
source /etc/profile.d/mpi.sh

# Check if mpirun is available
if command -v mpirun &> /dev/null; then
    log_info "✓ mpirun is available"
    mpirun --version | head -1
else
    log_error "✗ mpirun not found"
fi

# Check Python MPI
if python3 -c "import mpi4py; print('✓ mpi4py imported successfully')" 2>/dev/null; then
    log_info "✓ Python MPI (mpi4py) is working"
else
    log_error "✗ Python MPI (mpi4py) not working"
fi

log_info "MPI installation completed!"
log_info ""
log_info "To test MPI functionality:"
log_info "  1. Run: mpirun -np 4 /usr/local/bin/test_mpi.py"
log_info "  2. Or submit a job: /usr/local/bin/submit_mpi_job.sh mandelbrot_mpi.py"
log_info ""
log_info "Note: You may need to restart containers for full MPI functionality"
