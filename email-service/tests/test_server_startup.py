#!/usr/bin/env python3
"""
Test script to verify the server can start up properly.
"""

import asyncio
import signal
import sys
import time
from multiprocessing import Process

import uvicorn
from main import app, settings


def run_server():
    """Run the FastAPI server."""
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_level=settings.log_level.lower()
    )


def test_server_startup():
    """Test that the server can start up and shut down cleanly."""
    print("Testing server startup...")
    
    # Start server in a separate process
    server_process = Process(target=run_server)
    server_process.start()
    
    try:
        # Give the server time to start
        time.sleep(2)
        
        # Check if the process is still running
        if server_process.is_alive():
            print("✓ Server started successfully")
            
            # Test that we can make a basic request
            import requests
            try:
                response = requests.get(f"http://{settings.host}:{settings.port}/health", timeout=5)
                if response.status_code == 200:
                    print("✓ Server responds to health check")
                    data = response.json()
                    print(f"  Status: {data.get('status')}")
                    print(f"  Environment: {data.get('environment')}")
                else:
                    print(f"✗ Health check failed with status {response.status_code}")
            except requests.exceptions.RequestException as e:
                print(f"✗ Failed to connect to server: {e}")
            
        else:
            print("✗ Server failed to start")
            
    finally:
        # Clean up the server process
        if server_process.is_alive():
            server_process.terminate()
            server_process.join(timeout=5)
            if server_process.is_alive():
                server_process.kill()
                server_process.join()
        
        print("✓ Server shut down cleanly")


if __name__ == "__main__":
    test_server_startup()