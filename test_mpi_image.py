#!/usr/bin/env python3
from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

print(f"✓ MPI working: Rank {rank} of {size} processes")

if rank == 0:
    print("✓ MPI image test completed successfully!")
