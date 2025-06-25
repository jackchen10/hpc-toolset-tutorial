import socket
import time

def test_port(host, port, timeout=3):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

ports = {
    "ColdFront": 2443,
    "OnDemand": 3443, 
    "XDMoD": 4443,
    "SSH": 6222
}

print("Testing HPC Toolset ports...")
print("=" * 40)

for service, port in ports.items():
    status = "✓ OPEN" if test_port("localhost", port) else "✗ CLOSED"
    print(f"{service:12} (port {port}): {status}")

print("=" * 40)
print("If ports are open, try accessing:")
print("https://localhost:2443 (ColdFront)")
print("https://localhost:3443 (OnDemand)")  
print("https://localhost:4443 (XDMoD)")
