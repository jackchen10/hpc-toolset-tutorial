#!/usr/bin/env python3
"""
Simple MPI test script
"""
from mpi4py import MPI
import os

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = os.uname().nodename

print(f"MPI test: rank {rank} of {size} processes on {hostname}")

if rank == 0:
    print("✓ MPI is working correctly!")
