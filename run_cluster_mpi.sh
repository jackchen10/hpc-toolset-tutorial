#!/bin/bash

# Run MPI across the HPC cluster nodes
# This script uses the existing cpn01 and cpn02 containers

set -e

echo "=== Cluster MPI Test ==="
echo "Setting up MPI environment across cluster nodes..."

# Get container IPs
CPN01_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn01)
CPN02_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn02)

echo "CPN01 IP: $CPN01_IP"
echo "CPN02 IP: $CPN02_IP"

# Create hostfile
cat > hostfile << EOF
$CPN01_IP slots=2
$CPN02_IP slots=2
EOF

echo "Created hostfile:"
cat hostfile

# Copy hostfile to containers
docker cp hostfile cpn01:/tmp/
docker cp hostfile cpn02:/tmp/

# Run MPI test on cpn01
echo "Running MPI test across cluster nodes..."
docker exec cpn01 bash -c "
    export PATH=/usr/lib64/openmpi/bin:\$PATH
    export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:\$LD_LIBRARY_PATH
    export OMPI_ALLOW_RUN_AS_ROOT=1
    export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
    
    cd /tmp
    mpirun --allow-run-as-root -np 4 --mca btl ^openib --mca plm_rsh_agent '' /usr/bin/python3 /workspace/mpi_node_test.py
"

echo "=== Cluster MPI Test Complete ==="
