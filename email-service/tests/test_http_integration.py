#!/usr/bin/env python3
"""
Integration test using actual HTTP requests to verify the API endpoints.
"""

import json
import time
import urllib.request
import urllib.parse
from multiprocessing import Process
from unittest.mock import patch

import uvicorn
from main import app, settings


def run_test_server():
    """Run the FastAPI server for testing."""
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8001,  # Use different port to avoid conflicts
        log_level="error"  # Reduce log noise during testing
    )


def make_http_request(method, url, data=None):
    """Make an HTTP request using urllib."""
    if data:
        data = json.dumps(data).encode('utf-8')
    
    req = urllib.request.Request(
        url,
        data=data,
        headers={'Content-Type': 'application/json'} if data else {}
    )
    req.get_method = lambda: method
    
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.getcode(), json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode('utf-8'))
    except Exception as e:
        return None, str(e)


def test_http_endpoints():
    """Test all endpoints with actual HTTP requests."""
    base_url = "http://127.0.0.1:8001"
    
    print("Testing HTTP endpoints...")
    
    # Test root endpoint
    print("1. Testing GET /")
    status, data = make_http_request("GET", f"{base_url}/")
    assert status == 200, f"Expected 200, got {status}"
    assert data["message"] == "Goalkeeper Email Service"
    print("   ✓ Root endpoint works")
    
    # Test health endpoint
    print("2. Testing GET /health")
    with patch('main.email_service.health_check') as mock_health:
        mock_health.return_value = {"overall": "healthy"}
        
        status, data = make_http_request("GET", f"{base_url}/health")
        assert status == 200, f"Expected 200, got {status}"
        assert data["status"] == "healthy"
        print("   ✓ Health endpoint works")
    
    # Test send confirmation endpoint
    print("3. Testing POST /api/v1/send-confirmation")
    with patch('main.email_service.send_confirmation_email') as mock_send:
        from app.models.responses import EmailResponse
        mock_send.return_value = EmailResponse(
            success=True,
            message="Email sent",
            message_id="test-123"
        )
        
        status, data = make_http_request(
            "POST",
            f"{base_url}/api/v1/send-confirmation",
            {"email": "test@example.com", "user_id": "user123"}
        )
        assert status == 200, f"Expected 200, got {status}"
        assert data["success"] is True
        print("   ✓ Send confirmation endpoint works")
    
    # Test send password reset endpoint
    print("4. Testing POST /api/v1/send-password-reset")
    with patch('main.email_service.send_password_reset_email') as mock_send:
        from app.models.responses import EmailResponse
        mock_send.return_value = EmailResponse(
            success=True,
            message="Email sent",
            message_id="test-456"
        )
        
        status, data = make_http_request(
            "POST",
            f"{base_url}/api/v1/send-password-reset",
            {"email": "test@example.com", "user_id": "user123"}
        )
        assert status == 200, f"Expected 200, got {status}"
        assert data["success"] is True
        print("   ✓ Send password reset endpoint works")
    
    # Test validate code endpoint
    print("5. Testing POST /api/v1/validate-code")
    with patch('main.auth_code_service.validate_code') as mock_validate, \
         patch('main.auth_code_service.invalidate_code') as mock_invalidate:
        
        # Mock a valid auth code
        from unittest.mock import MagicMock
        mock_auth_code = MagicMock()
        mock_auth_code.user_id = "user123"
        
        mock_validate.return_value = mock_auth_code
        mock_invalidate.return_value = True
        
        status, data = make_http_request(
            "POST",
            f"{base_url}/api/v1/validate-code",
            {"code": "test-code", "code_type": "email_confirmation"}
        )
        assert status == 200, f"Expected 200, got {status}"
        assert data["valid"] is True
        assert data["user_id"] == "user123"
        print("   ✓ Validate code endpoint works")
    
    # Test validation error
    print("6. Testing validation error handling")
    status, data = make_http_request(
        "POST",
        f"{base_url}/api/v1/send-confirmation",
        {"email": "invalid-email", "user_id": "user123"}
    )
    assert status == 422, f"Expected 422, got {status}"
    print("   ✓ Validation error handling works")
    
    print("\n✅ All HTTP endpoint tests passed!")


def main():
    """Run the HTTP integration test."""
    print("Starting HTTP integration test...")
    
    # Start server in a separate process
    server_process = Process(target=run_test_server)
    server_process.start()
    
    try:
        # Give the server time to start
        print("Waiting for server to start...")
        time.sleep(3)
        
        if server_process.is_alive():
            test_http_endpoints()
        else:
            print("❌ Server failed to start")
            return False
            
    finally:
        # Clean up the server process
        if server_process.is_alive():
            server_process.terminate()
            server_process.join(timeout=5)
            if server_process.is_alive():
                server_process.kill()
                server_process.join()
    
    return True


if __name__ == "__main__":
    success = main()
    if not success:
        exit(1)