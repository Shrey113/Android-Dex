import signal
import sys
import time
from zeroconf import Zeroconf
from mdns_service import register_mdns_service, safe_print

shutdown_requested = False


def handle_shutdown(signum=None, frame=None):
    global shutdown_requested
    shutdown_requested = True
    safe_print("\nShutdown signal received.")


def main():
    global shutdown_requested
    
    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)
    
    zeroconf = Zeroconf()
    register_mdns_service(zeroconf)
    
    safe_print("mDNS service running. Press Ctrl+C to stop.")
    try:
        while not shutdown_requested:
            time.sleep(1)
    except KeyboardInterrupt:
        handle_shutdown()
    
    safe_print("Shutting down...")
    zeroconf.close()
    sys.exit(0)


if __name__ == "__main__":
    main()
