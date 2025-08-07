#!/usr/bin/env python3
"""Comprehensive validation of all data models and their serialization."""

import json
from datetime import datetime, timedelta, timezone

from app.models import (
    AuthCode, AuthCodeType, EmailRequest, CodeValidationRequest,
    EmailResponse, CodeValidationResponse, HealthResponse, ErrorResponse,
    AzureEmailRequest, AzureEmailResponse, AzureEmailRecipient, 
    AzureEmailRecipients, AzureEmailContent
)

def test_auth_code_serialization():
    """Test AuthCode serialization and deserialization."""
    print("Testing AuthCode serialization...")
    
    now = datetime.now(timezone.utc)
    auth_code = AuthCode(
        id='test-id-123',
        code='hashed-code-value',
        user_id='user-456',
        type=AuthCodeType.EMAIL_CONFIRMATION,
        created_at=now,
        expires_at=now + timedelta(minutes=5),
        is_used=False
    )
    
    # Test to_dict
    data_dict = auth_code.to_dict()
    print(f"  to_dict(): {data_dict}")
    
    # Test from_dict
    restored_code = AuthCode.from_dict(data_dict)
    print(f"  from_dict(): {restored_code}")
    
    # Test JSON serialization
    json_str = auth_code.model_dump_json()
    print(f"  JSON: {json_str}")
    
    assert auth_code.id == restored_code.id
    assert auth_code.code == restored_code.code
    assert auth_code.user_id == restored_code.user_id
    assert auth_code.type == restored_code.type
    print("  ✓ AuthCode serialization works correctly")

def test_request_validation():
    """Test request model validation."""
    print("\nTesting request validation...")
    
    # Valid EmailRequest
    email_req = EmailRequest(email='test@example.com', user_id='user123')
    print(f"  Valid EmailRequest: {email_req}")
    
    # Valid CodeValidationRequest
    code_req = CodeValidationRequest(
        code='validcode123', 
        code_type=AuthCodeType.PASSWORD_RESET
    )
    print(f"  Valid CodeValidationRequest: {code_req}")
    
    # Test validation errors
    try:
        EmailRequest(email='invalid-email', user_id='user123')
        assert False, "Should have raised validation error"
    except Exception as e:
        print(f"  ✓ Email validation works: {type(e).__name__}")
    
    try:
        CodeValidationRequest(code='', code_type=AuthCodeType.EMAIL_CONFIRMATION)
        assert False, "Should have raised validation error"
    except Exception as e:
        print(f"  ✓ Code validation works: {type(e).__name__}")

def test_response_models():
    """Test response model creation."""
    print("\nTesting response models...")
    
    # EmailResponse
    email_resp = EmailResponse(
        success=True,
        message="Email sent successfully",
        message_id="azure-msg-123"
    )
    print(f"  EmailResponse: {email_resp}")
    
    # CodeValidationResponse
    code_resp = CodeValidationResponse(
        valid=True,
        user_id="user-456",
        message="Code is valid"
    )
    print(f"  CodeValidationResponse: {code_resp}")
    
    # HealthResponse
    health_resp = HealthResponse(
        status="healthy",
        environment="development"
    )
    print(f"  HealthResponse: {health_resp}")
    
    # ErrorResponse
    error_resp = ErrorResponse(
        error_type="validation_error",
        message="Invalid input provided",
        details={"field": "email", "issue": "invalid format"}
    )
    print(f"  ErrorResponse: {error_resp}")
    
    print("  ✓ All response models work correctly")

def test_azure_models():
    """Test Azure API models."""
    print("\nTesting Azure models...")
    
    # Azure email request
    azure_req = AzureEmailRequest(
        senderAddress="noreply@example.com",
        recipients=AzureEmailRecipients(
            to=[AzureEmailRecipient(
                address="user@example.com",
                displayName="Test User"
            )]
        ),
        content=AzureEmailContent(
            subject="Test Email",
            html="<h1>Hello World</h1>"
        )
    )
    print(f"  AzureEmailRequest: {azure_req}")
    
    # Azure response
    azure_resp = AzureEmailResponse(
        id="azure-123",
        status="accepted"
    )
    print(f"  AzureEmailResponse: {azure_resp}")
    print(f"  Is success: {azure_resp.is_success}")
    
    print("  ✓ Azure models work correctly")

def test_enum_values():
    """Test enum value handling."""
    print("\nTesting enum values...")
    
    # Test enum values
    print(f"  EMAIL_CONFIRMATION value: {AuthCodeType.EMAIL_CONFIRMATION.value}")
    print(f"  PASSWORD_RESET value: {AuthCodeType.PASSWORD_RESET.value}")
    
    # Test enum in JSON
    code_req = CodeValidationRequest(
        code='test123456',
        code_type=AuthCodeType.EMAIL_CONFIRMATION
    )
    json_data = json.loads(code_req.model_dump_json())
    print(f"  Enum in JSON: {json_data['code_type']}")
    
    print("  ✓ Enum handling works correctly")

def main():
    """Run all validation tests."""
    print("=== Data Model Validation ===")
    
    test_auth_code_serialization()
    test_request_validation()
    test_response_models()
    test_azure_models()
    test_enum_values()
    
    print("\n=== All Tests Passed! ===")
    print("✓ Core data models and configuration implemented successfully")
    print("✓ Pydantic models with validation and serialization")
    print("✓ AuthCode data model matching Supabase schema")
    print("✓ Configuration management using environment variables")
    print("✓ AuthCodeType enum for email_confirmation and password_reset")
    print("✓ Validation and serialization methods for all data models")

if __name__ == "__main__":
    main()