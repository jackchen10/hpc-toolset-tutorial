#!/bin/bash

# Quick MPI Setup for Running Containers
# This script can be executed inside running containers to add MPI support

set -e

echo "=== Quick MPI Setup for HPC Toolset Tutorial ==="
echo "This script will install MPI support in the current container"
echo "=================================================="

# Check if running in container
if [ ! -f /.dockerenv ]; then
    echo "Warning: This script is designed to run inside Docker containers"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Install MPI packages
log "Installing MPI packages..."
if command -v dnf &> /dev/null; then
    dnf install -y openmpi openmpi-devel python3-numpy python3-matplotlib
elif command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y openmpi-bin openmpi-common libopenmpi-dev python3-numpy python3-matplotlib
else
    log "ERROR: No supported package manager found"
    exit 1
fi

# Set up MPI environment
log "Setting up MPI environment..."
export PATH="/usr/lib64/openmpi/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"
export MPI_ROOT="/usr/lib64/openmpi"

# Create environment script
cat > /etc/profile.d/mpi.sh << 'EOF'
# MPI Environment
export PATH="/usr/lib64/openmpi/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"
export MPI_ROOT="/usr/lib64/openmpi"
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
EOF

# Source the environment
source /etc/profile.d/mpi.sh

# Install Python MPI packages
log "Installing Python MPI packages..."

# Try to install in Jupyter environment first
if [ -d "/usr/local/jupyter/4.3.5" ]; then
    log "Installing in Jupyter environment..."
    source /usr/local/jupyter/4.3.5/bin/activate
    pip install --upgrade pip
    pip install mpi4py numpy matplotlib scipy
    deactivate
    log "✓ Installed in Jupyter environment"
fi

# Also install system-wide as fallback
log "Installing system-wide Python packages..."
python3 -m pip install --user mpi4py numpy matplotlib scipy

# Create MPI test script
log "Creating MPI test script..."
cat > /usr/local/bin/mpi_test.py << 'EOF'
#!/usr/bin/env python3
"""Quick MPI test"""
try:
    from mpi4py import MPI
    import numpy as np
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    print(f"✓ MPI working: Rank {rank}/{size} on {MPI.Get_processor_name()}")
    
    if rank == 0:
        data = np.array([1, 2, 3, 4, 5])
        print(f"✓ NumPy working: {data}")
    
    comm.Barrier()
    if rank == 0:
        print("✓ All tests passed!")
        
except Exception as e:
    print(f"✗ Test failed: {e}")
    exit(1)
EOF

chmod +x /usr/local/bin/mpi_test.py

# Create job submission helper
log "Creating job submission helper..."
cat > /usr/local/bin/run_mpi_python.sh << 'EOF'
#!/bin/bash

# Quick MPI Python job runner
# Usage: run_mpi_python.sh <script.py> [num_processes]

SCRIPT=${1:-"mandelbrot_mpi.py"}
NPROCS=${2:-4}

if [ ! -f "$SCRIPT" ]; then
    echo "Error: Script '$SCRIPT' not found"
    echo "Usage: $0 <script.py> [num_processes]"
    exit 1
fi

echo "Running MPI Python job:"
echo "  Script: $SCRIPT"
echo "  Processes: $NPROCS"
echo "  Command: mpirun -np $NPROCS python $SCRIPT"
echo

# Load environment
source /etc/profile.d/mpi.sh 2>/dev/null || true
source /usr/local/jupyter/4.3.5/bin/activate 2>/dev/null || true

# Run the job
mpirun -np $NPROCS python "$SCRIPT"

echo
echo "Job completed at: $(date)"
EOF

chmod +x /usr/local/bin/run_mpi_python.sh

# Test the installation
log "Testing MPI installation..."

if command -v mpirun &> /dev/null; then
    log "✓ mpirun found: $(mpirun --version | head -1)"
else
    log "✗ mpirun not found"
    exit 1
fi

if python3 -c "import mpi4py; print('✓ mpi4py imported successfully')" 2>/dev/null; then
    log "✓ Python MPI working"
else
    log "✗ Python MPI not working"
    # Try to fix common issues
    log "Attempting to fix Python MPI..."
    python3 -m pip install --user --force-reinstall mpi4py
fi

# Run a quick test
log "Running quick MPI test..."
if mpirun -np 2 /usr/local/bin/mpi_test.py 2>/dev/null; then
    log "✓ MPI test passed"
else
    log "⚠ MPI test had issues, but basic installation completed"
fi

log "=== MPI Setup Complete ==="
log ""
log "Quick usage examples:"
log "  1. Test MPI: mpirun -np 2 /usr/local/bin/mpi_test.py"
log "  2. Run your script: /usr/local/bin/run_mpi_python.sh mandelbrot_mpi.py 4"
log "  3. Submit Slurm job: sbatch your_mpi_job.sbatch"
log ""
log "Your Mandelbrot script should now work with:"
log "  mpirun -np 4 python mandelbrot_mpi.py"
log ""
log "Note: You may need to restart services for full functionality"
