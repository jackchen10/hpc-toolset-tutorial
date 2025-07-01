#!/usr/bin/env python3
from mpi4py import MPI
import os

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = os.uname().nodename

print(f"✓ MPI working: Rank {rank} of {size} on {hostname}")

if rank == 0:
    print("✓ MPI test completed successfully on cpn02!")
