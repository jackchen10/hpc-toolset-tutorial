#!/bin/bash

# Multi-node MPI test script
# This script runs MPI across multiple Docker containers

set -e

echo "=== Multi-Node MPI Test ==="
echo "Setting up MPI environment across containers..."

# Create a shared network if it doesn't exist
docker network create mpi-network 2>/dev/null || true

# Start two MPI-enabled containers
echo "Starting MPI containers..."

# Container 1 (master)
docker run -d --name mpi-master --network mpi-network \
    -v "${PWD}:/workspace" \
    hpcts-mpi:cpn02 \
    bash -c "
    # Install SSH server
    yum install -y openssh-server openssh-clients
    ssh-keygen -A
    
    # Set up passwordless SSH
    ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    
    # Start SSH daemon
    /usr/sbin/sshd -D
    " &

# Container 2 (worker)
docker run -d --name mpi-worker --network mpi-network \
    -v "${PWD}:/workspace" \
    hpcts-mpi:cpn02 \
    bash -c "
    # Install SSH server
    yum install -y openssh-server openssh-clients
    ssh-keygen -A
    
    # Start SSH daemon
    /usr/sbin/sshd -D
    " &

echo "Waiting for containers to start..."
sleep 10

# Get container IPs
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mpi-master)
WORKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mpi-worker)

echo "Master IP: $MASTER_IP"
echo "Worker IP: $WORKER_IP"

# Create hostfile
cat > hostfile << EOF
$MASTER_IP slots=2
$WORKER_IP slots=2
EOF

echo "Created hostfile:"
cat hostfile

# Copy SSH keys and hostfile to containers
docker cp hostfile mpi-master:/workspace/
docker cp hostfile mpi-worker:/workspace/

# Set up SSH keys between containers
docker exec mpi-master bash -c "
    # Copy public key to worker
    sshpass -p 'root' ssh-copy-id -o StrictHostKeyChecking=no root@$WORKER_IP
"

# Run MPI test
echo "Running MPI test across nodes..."
docker exec mpi-master bash -c "
    export PATH=/usr/lib64/openmpi/bin:\$PATH
    export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:\$LD_LIBRARY_PATH
    export OMPI_ALLOW_RUN_AS_ROOT=1
    export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
    
    cd /workspace
    mpirun --hostfile hostfile -np 4 /usr/bin/python3 mpi_node_test.py
"

# Cleanup
echo "Cleaning up..."
docker stop mpi-master mpi-worker
docker rm mpi-master mpi-worker
docker network rm mpi-network

echo "=== Multi-Node Test Complete ==="
