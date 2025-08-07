#!/usr/bin/env python3
"""
Test script for FastAPI endpoints.

This script tests the basic functionality of all API endpoints
without requiring external services.
"""

import asyncio
import json
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from fastapi.testclient import TestClient

from main import app


def test_root_endpoint():
    """Test the root endpoint."""
    print("Testing root endpoint...")
    
    with TestClient(app) as client:
        response = client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["message"] == "Goalkeeper Email Service"
        assert data["version"] == "0.1.0"
        assert data["status"] == "running"
        assert "endpoints" in data
        
        print("✓ Root endpoint test passed")


def test_health_endpoint():
    """Test the health check endpoint."""
    print("Testing health endpoint...")
    
    # Mock the email service health check
    with patch('main.email_service.health_check') as mock_health:
        mock_health.return_value = {
            "overall": "healthy",
            "email_service": "healthy",
            "auth_code_service": "healthy",
            "template_manager": "healthy",
            "azure_client": "healthy"
        }
        
        with TestClient(app) as client:
            response = client.get("/health")
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["status"] == "healthy"
            assert "timestamp" in data
            assert data["version"] == "0.1.0"
            
            print("✓ Health endpoint test passed")


def test_send_confirmation_endpoint():
    """Test the send confirmation email endpoint."""
    print("Testing send confirmation endpoint...")
    
    # Mock the email service
    with patch('main.email_service.send_confirmation_email') as mock_send:
        mock_send.return_value = AsyncMock(
            success=True,
            message="Confirmation email sent successfully",
            message_id="test-message-id-123"
        )
        
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/send-confirmation",
                json={
                    "email": "test@example.com",
                    "user_id": "test-user-123"
                }
            )
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["success"] is True
            assert data["message"] == "Confirmation email sent successfully"
            assert data["message_id"] == "test-message-id-123"
            
            print("✓ Send confirmation endpoint test passed")


def test_send_password_reset_endpoint():
    """Test the send password reset email endpoint."""
    print("Testing send password reset endpoint...")
    
    # Mock the email service
    with patch('main.email_service.send_password_reset_email') as mock_send:
        mock_send.return_value = AsyncMock(
            success=True,
            message="Password reset email sent successfully",
            message_id="test-message-id-456"
        )
        
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/send-password-reset",
                json={
                    "email": "test@example.com",
                    "user_id": "test-user-123"
                }
            )
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["success"] is True
            assert data["message"] == "Password reset email sent successfully"
            assert data["message_id"] == "test-message-id-456"
            
            print("✓ Send password reset endpoint test passed")


def test_validate_code_endpoint():
    """Test the validate authentication code endpoint."""
    print("Testing validate code endpoint...")
    
    # Mock the auth code service
    mock_auth_code = MagicMock()
    mock_auth_code.user_id = "test-user-123"
    
    with patch('main.auth_code_service.validate_code') as mock_validate, \
         patch('main.auth_code_service.invalidate_code') as mock_invalidate:
        
        mock_validate.return_value = mock_auth_code
        mock_invalidate.return_value = True
        
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/validate-code",
                json={
                    "code": "test-auth-code-123",
                    "code_type": "email_confirmation"
                }
            )
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["valid"] is True
            assert data["user_id"] == "test-user-123"
            assert data["message"] == "Authentication code is valid"
            
            print("✓ Validate code endpoint test passed")


def test_validate_code_invalid():
    """Test the validate authentication code endpoint with invalid code."""
    print("Testing validate code endpoint with invalid code...")
    
    with patch('main.auth_code_service.validate_code') as mock_validate:
        mock_validate.return_value = None  # Invalid code
        
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/validate-code",
                json={
                    "code": "invalid-code",
                    "code_type": "email_confirmation"
                }
            )
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["valid"] is False
            assert data["user_id"] is None
            assert "invalid" in data["message"].lower()
            
            print("✓ Validate invalid code endpoint test passed")


def test_validation_errors():
    """Test validation error handling."""
    print("Testing validation error handling...")
    
    with TestClient(app) as client:
        # Test missing email
        response = client.post(
            "/api/v1/send-confirmation",
            json={
                "user_id": "test-user-123"
                # Missing email field
            }
        )
        assert response.status_code == 422  # Validation error
        
        # Test invalid email format
        response = client.post(
            "/api/v1/send-confirmation",
            json={
                "email": "invalid-email",
                "user_id": "test-user-123"
            }
        )
        assert response.status_code == 422  # Validation error
        
        # Test empty user_id
        response = client.post(
            "/api/v1/send-confirmation",
            json={
                "email": "test@example.com",
                "user_id": ""
            }
        )
        assert response.status_code == 422  # Validation error
        
        print("✓ Validation error handling test passed")


def main():
    """Run all tests."""
    print("Running FastAPI endpoint tests...\n")
    
    try:
        test_root_endpoint()
        test_health_endpoint()
        test_send_confirmation_endpoint()
        test_send_password_reset_endpoint()
        test_validate_code_endpoint()
        test_validate_code_invalid()
        test_validation_errors()
        
        print("\n✅ All API endpoint tests passed!")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        raise


if __name__ == "__main__":
    main()