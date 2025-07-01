#!/bin/bash

# Build MPI-enabled HPC Toolset Tutorial Images
# This script builds Docker images with MPI support for the HPC environment

set -e

# Configuration
HPCTS_VERSION=${HPCTS_VERSION:-latest}
SLURM_VERSION=${SLURM_VERSION:-23.11.10}
IMAGE_TAG=${IMAGE_TAG:-hpcts-mpi}

echo "=== Building MPI-enabled HPC Toolset Tutorial Images ==="
echo "HPCTS Version: $HPCTS_VERSION"
echo "Slurm Version: $SLURM_VERSION"
echo "Image Tag: $IMAGE_TAG"
echo "=================================================="

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Build the MPI-enabled Slurm image
log "Building MPI-enabled Slurm image..."
docker build \
    --build-arg HPCTS_VERSION=$HPCTS_VERSION \
    --build-arg SLURM_VERSION=$SLURM_VERSION \
    -f slurm/Dockerfile.mpi-simple \
    -t $IMAGE_TAG:slurm-$SLURM_VERSION \
    slurm/

if [ $? -eq 0 ]; then
    log "✓ MPI-enabled Slurm image built successfully"
else
    log "✗ Failed to build MPI-enabled Slurm image"
    exit 1
fi

# Tag the image with latest
docker tag $IMAGE_TAG:slurm-$SLURM_VERSION $IMAGE_TAG:latest

log "✓ Image tagged as $IMAGE_TAG:latest"

# Test the MPI installation in the image
log "Testing MPI installation in the image..."
docker run --rm $IMAGE_TAG:latest bash -c "
    source /etc/profile.d/mpi.sh
    mpirun --version
    python3 -c 'from mpi4py import MPI; print(f\"MPI test: {MPI.COMM_WORLD.Get_size()} processes\")'
"

if [ $? -eq 0 ]; then
    log "✓ MPI test passed"
else
    log "⚠ MPI test had issues, but image was built"
fi

# Show image information
log "Image information:"
docker images | grep $IMAGE_TAG

log "=== Build Complete ==="
log ""
log "To use the MPI-enabled environment:"
log "  1. Start with: docker compose -f docker-compose.mpi.yml up -d"
log "  2. Access OnDemand: https://localhost:3443"
log "  3. Submit MPI jobs through the web interface or command line"
log ""
log "To test MPI functionality:"
log "  docker exec frontend mpirun -np 2 /usr/local/bin/test_mpi.py"
log ""
log "Image tags created:"
log "  - $IMAGE_TAG:slurm-$SLURM_VERSION"
log "  - $IMAGE_TAG:latest"
