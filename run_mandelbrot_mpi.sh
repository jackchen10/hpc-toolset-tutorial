#!/bin/bash

# Run Mandelbrot MPI calculation using the pre-built Docker image
# This script demonstrates how to use the MPI-enabled image

set -e

echo "=== Mandelbrot MPI Calculation with Docker ==="
echo "Using pre-built MPI-enabled Docker image"
echo "=============================================="

# Configuration
IMAGE_NAME="hpcts-mpi:cpn02"
SCRIPT_NAME="mandelbrot_simple.py"
NUM_PROCESSES=${1:-2}
OUTPUT_DIR="./mpi_results"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Configuration:"
echo "  Image: $IMAGE_NAME"
echo "  Script: $SCRIPT_NAME"
echo "  Processes: $NUM_PROCESSES"
echo "  Output: $OUTPUT_DIR"
echo

# Check if image exists
if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
    echo "Error: Docker image $IMAGE_NAME not found!"
    echo "Please run the following command first:"
    echo "  docker commit cpn02 hpcts-mpi:cpn02"
    exit 1
fi

# Check if script exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "Error: Script $SCRIPT_NAME not found!"
    echo "Please ensure the Mandelbrot script is in the current directory."
    exit 1
fi

echo "Starting MPI Mandelbrot calculation..."
echo "Command: docker run --rm -v \${PWD}:/workspace $IMAGE_NAME ..."
echo

# Run the MPI calculation
docker run --rm -v "${PWD}:/workspace" "$IMAGE_NAME" bash -c "
# Set up MPI environment
export PATH=/usr/lib64/openmpi/bin:\$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:\$LD_LIBRARY_PATH
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=/usr/bin/ssh

# Change to workspace
cd /workspace

# Run MPI calculation
echo 'Starting MPI calculation with $NUM_PROCESSES processes...'
mpirun -np $NUM_PROCESSES /usr/bin/python3 $SCRIPT_NAME

# Check results
if [ -f 'mandelbrot_mpi_test.png' ]; then
    echo '✓ Calculation completed successfully!'
    echo '  Output file: mandelbrot_mpi_test.png'
    ls -lh mandelbrot_mpi_test.png
else
    echo '✗ Output file not found'
    exit 1
fi
"

# Copy results to output directory
if [ -f "mandelbrot_mpi_test.png" ]; then
    cp mandelbrot_mpi_test.png "$OUTPUT_DIR/"
    echo
    echo "=== Results ==="
    echo "✓ Mandelbrot image saved to: $OUTPUT_DIR/mandelbrot_mpi_test.png"
    echo "✓ File size: $(ls -lh mandelbrot_mpi_test.png | awk '{print $5}')"
    echo
    echo "To view the image:"
    echo "  start $OUTPUT_DIR/mandelbrot_mpi_test.png"
else
    echo "✗ No output file to copy"
    exit 1
fi

echo "=== MPI Calculation Complete ==="
