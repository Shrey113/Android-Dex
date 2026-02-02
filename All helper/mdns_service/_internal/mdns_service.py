import socket
import json
from zeroconf import Zeroconf, ServiceInfo

SERVICE_TYPE = "_httpapp._tcp.local."
HTTP_PORT = 5001


def safe_print(msg):
    print(msg, flush=True)


def get_network_info():
    hostname = socket.gethostname()
    ip = socket.gethostbyname(hostname)
    return hostname, ip


def register_mdns_service(zeroconf):
    hostname, ip = get_network_info()
    service_name = f"{ip.replace('.', '_')}_win_server._httpapp._tcp.local."
    
    device_data = {
        "status": "success",
        "device_type": "windows",
        "device_info": {
            "hostname": hostname,
            "ip": ip,
        }
    }
    
    info = ServiceInfo(
        SERVICE_TYPE,
        service_name,
        addresses=[socket.inet_aton(ip)],
        port=HTTP_PORT,
        properties={
            b"host": hostname.encode(),
            b"device_type": b"windows",
            b"ip": ip.encode(),
            b"device_data": json.dumps(device_data).encode()
        },
        server=hostname + ".local.",
    )
    
    zeroconf.register_service(info)
    safe_print(f"Registered mDNS: {service_name} ({ip}:{HTTP_PORT})")
    return info
