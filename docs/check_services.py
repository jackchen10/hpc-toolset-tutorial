#!/usr/bin/env python3
import subprocess
import socket
import time
import sys

def check_port(host, port, timeout=3):
    """检查端口是否可访问"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def run_command(cmd):
    """运行命令并返回输出"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"
    except Exception as e:
        return False, "", str(e)

def main():
    print("=" * 50)
    print("HPC Toolset Tutorial - Service Status Check")
    print("=" * 50)
    
    # 检查Docker是否运行
    print("\n1. Checking Docker status...")
    success, stdout, stderr = run_command("docker --version")
    if success:
        print(f"✓ Docker is available: {stdout.strip()}")
    else:
        print(f"✗ Docker not available: {stderr}")
        return
    
    # 检查Docker Compose
    print("\n2. Checking Docker Compose...")
    success, stdout, stderr = run_command("docker compose version")
    if success:
        print(f"✓ Docker Compose is available")
    else:
        print(f"✗ Docker Compose not available: {stderr}")
        return
    
    # 检查容器状态
    print("\n3. Checking container status...")
    success, stdout, stderr = run_command("docker compose ps")
    if success:
        print("Container status:")
        print(stdout)
    else:
        print(f"✗ Failed to get container status: {stderr}")
    
    # 检查端口
    print("\n4. Checking service ports...")
    services = {
        "ColdFront": 2443,
        "OnDemand": 3443,
        "XDMoD": 4443,
        "SSH": 6222
    }
    
    for service, port in services.items():
        if check_port("localhost", port):
            print(f"✓ {service} (port {port}) is accessible")
        else:
            print(f"✗ {service} (port {port}) is not accessible")
    
    print("\n" + "=" * 50)
    print("Service URLs:")
    print("ColdFront:  https://localhost:2443")
    print("OnDemand:   https://localhost:3443") 
    print("XDMoD:      https://localhost:4443")
    print("SSH Login:  ssh -p 6222 hpcadmin@localhost")
    print("=" * 50)
    
    print("\nDefault credentials:")
    print("Username: admin")
    print("Password: admin")
    print("(For LDAP users, password: ilovelinux)")

if __name__ == "__main__":
    main()
