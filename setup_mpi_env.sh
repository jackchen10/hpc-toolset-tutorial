#!/bin/bash

# Setup MPI environment
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=ssh

echo "MPI Environment configured:"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "MPI Version: $(mpirun --version | head -1)"

# Test MPI
echo "Testing MPI..."
/usr/bin/python3 /tmp/test_mpi.py
