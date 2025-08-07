#!/usr/bin/env python3
"""Unit tests for EmailService to verify error handling and logging."""

import asyncio
import logging
import sys
from pathlib import Path
from unittest.mock import Mock, AsyncMock, patch

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent))

from app.services.email_service import EmailService, EmailServiceError
from app.models.auth_code import AuthCodeType
from app.models.responses import EmailResponse
from app.services.auth_code_service import AuthCodeServiceError
from app.services.template_manager import TemplateManagerError
from app.clients.azure_client import AzureClientError, AzureResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


async def test_email_service_error_handling():
    """Test EmailService error handling scenarios."""
    
    print("=" * 60)
    print("EmailService Error Handling Tests")
    print("=" * 60)
    
    try:
        # Test 1: AuthCodeService error handling
        print("\n1. Testing AuthCodeService error handling...")
        
        mock_auth_service = Mock()
        mock_auth_service.generate_code.side_effect = AuthCodeServiceError("Database connection failed")
        
        mock_template_manager = Mock()
        mock_azure_client = AsyncMock()
        
        email_service = EmailService(
            auth_code_service=mock_auth_service,
            template_manager=mock_template_manager,
            azure_client=mock_azure_client
        )
        
        try:
            await email_service.send_confirmation_email("test@example.com", "user-123")
            print("✗ Expected EmailServiceError was not raised")
            return False
        except EmailServiceError as e:
            if "Failed to generate authentication code" in str(e):
                print("✓ AuthCodeService error properly handled and wrapped")
            else:
                print(f"✗ Unexpected error message: {e}")
                return False
        
        # Test 2: TemplateManager error handling
        print("\n2. Testing TemplateManager error handling...")
        
        mock_auth_service = Mock()
        mock_auth_service.generate_code.return_value = "test123456789012345678901234567890"
        
        mock_template_manager = Mock()
        mock_template_manager.render_email_by_type.side_effect = TemplateManagerError("Template not found")
        
        email_service = EmailService(
            auth_code_service=mock_auth_service,
            template_manager=mock_template_manager,
            azure_client=mock_azure_client
        )
        
        try:
            await email_service.send_password_reset_email("test@example.com", "user-123")
            print("✗ Expected EmailServiceError was not raised")
            return False
        except EmailServiceError as e:
            if "Failed to process email template" in str(e):
                print("✓ TemplateManager error properly handled and wrapped")
            else:
                print(f"✗ Unexpected error message: {e}")
                return False
        
        # Test 3: AzureClient error handling
        print("\n3. Testing AzureClient error handling...")
        
        mock_auth_service = Mock()
        mock_auth_service.generate_code.return_value = "test123456789012345678901234567890"
        
        mock_template_manager = Mock()
        mock_template_manager.render_email_by_type.return_value = "<html>Test email</html>"
        
        mock_azure_client = AsyncMock()
        mock_azure_client.send_email.side_effect = AzureClientError("Azure API unavailable", status_code=503)
        
        email_service = EmailService(
            auth_code_service=mock_auth_service,
            template_manager=mock_template_manager,
            azure_client=mock_azure_client
        )
        
        try:
            await email_service.send_confirmation_email("test@example.com", "user-123")
            print("✗ Expected EmailServiceError was not raised")
            return False
        except EmailServiceError as e:
            if "Failed to send email via Azure" in str(e):
                print("✓ AzureClient error properly handled and wrapped")
            else:
                print(f"✗ Unexpected error message: {e}")
                return False
        
        # Test 4: Successful email flow
        print("\n4. Testing successful email flow...")
        
        mock_auth_service = Mock()
        mock_auth_service.generate_code.return_value = "test123456789012345678901234567890"
        
        mock_template_manager = Mock()
        mock_template_manager.render_email_by_type.return_value = "<html>Test email</html>"
        
        mock_azure_client = AsyncMock()
        mock_azure_response = AzureResponse(
            success=True,
            message_id="azure-msg-123",
            status_code=200
        )
        mock_azure_client.send_email.return_value = mock_azure_response
        
        email_service = EmailService(
            auth_code_service=mock_auth_service,
            template_manager=mock_template_manager,
            azure_client=mock_azure_client
        )
        
        result = await email_service.send_confirmation_email("test@example.com", "user-123")
        
        if isinstance(result, EmailResponse) and result.success:
            print("✓ Successful email flow works correctly")
            print(f"  Message: {result.message}")
            print(f"  Message ID: {result.message_id}")
        else:
            print(f"✗ Unexpected result: {result}")
            return False
        
        # Test 5: Azure failure with cleanup
        print("\n5. Testing Azure failure with auth code cleanup...")
        
        mock_auth_service = Mock()
        mock_auth_service.generate_code.return_value = "test123456789012345678901234567890"
        mock_auth_service.invalidate_code.return_value = True
        
        mock_template_manager = Mock()
        mock_template_manager.render_email_by_type.return_value = "<html>Test email</html>"
        
        mock_azure_client = AsyncMock()
        mock_azure_response = AzureResponse(
            success=False,
            error_message="Rate limit exceeded",
            status_code=429
        )
        mock_azure_client.send_email.return_value = mock_azure_response
        
        email_service = EmailService(
            auth_code_service=mock_auth_service,
            template_manager=mock_template_manager,
            azure_client=mock_azure_client
        )
        
        result = await email_service.send_password_reset_email("test@example.com", "user-123")
        
        if isinstance(result, EmailResponse) and not result.success:
            print("✓ Azure failure properly handled")
            print(f"  Message: {result.message}")
            
            # Verify cleanup was attempted
            mock_auth_service.invalidate_code.assert_called_once()
            print("✓ Auth code cleanup was attempted")
        else:
            print(f"✗ Unexpected result: {result}")
            return False
        
        print("\n" + "=" * 60)
        print("✓ All EmailService error handling tests passed!")
        print("✓ EmailService properly handles all error scenarios")
        print("=" * 60)
        
        return True
        
    except Exception as e:
        print(f"\n✗ EmailService error handling test failed: {e}")
        logger.exception("Error handling test failed")
        return False


if __name__ == "__main__":
    success = asyncio.run(test_email_service_error_handling())
    sys.exit(0 if success else 1)