#!/usr/bin/env python3
"""
Simple MPI test to verify multi-node communication
"""

import os
import socket
from datetime import datetime
from mpi4py import MPI

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    # Get node information
    hostname = socket.gethostname()
    pid = os.getpid()
    
    # Print node information
    print(f"[{datetime.now()}] Rank {rank}/{size} on {hostname} (PID: {pid})")
    
    # Barrier to synchronize all processes
    comm.Barrier()
    
    if rank == 0:
        print(f"\n=== MPI Node Test Results ===")
        print(f"Total processes: {size}")
        
        # Collect hostname information from all ranks
        hostnames = [hostname]
        for i in range(1, size):
            data = comm.recv(source=i, tag=11)
            hostnames.append(data)
        
        # Count unique nodes
        unique_hosts = set(hostnames)
        print(f"Unique nodes: {len(unique_hosts)}")
        print(f"Node list: {list(unique_hosts)}")
        
        # Show distribution
        for host in unique_hosts:
            count = hostnames.count(host)
            print(f"  {host}: {count} processes")
            
        print("=== Test Complete ===\n")
    else:
        # Send hostname to rank 0
        comm.send(hostname, dest=0, tag=11)
    
    comm.Barrier()

if __name__ == "__main__":
    main()
