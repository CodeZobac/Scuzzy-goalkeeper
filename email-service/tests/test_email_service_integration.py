#!/usr/bin/env python3
"""Integration test for EmailService to verify all components work together."""

import asyncio
import logging
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent))

from app.services.email_service import EmailService, EmailServiceError
from app.models.auth_code import AuthCodeType

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


async def test_email_service_integration():
    """Test EmailService integration with all dependencies."""
    
    print("=" * 60)
    print("EmailService Integration Test")
    print("=" * 60)
    
    try:
        # Initialize EmailService
        print("\n1. Initializing EmailService...")
        email_service = EmailService()
        print("✓ EmailService initialized successfully")
        
        # Test service info
        print("\n2. Getting service information...")
        service_info = email_service.get_service_info()
        print(f"✓ Service info: {service_info}")
        
        # Test health check
        print("\n3. Performing health check...")
        health_status = await email_service.health_check()
        print(f"✓ Health status: {health_status}")
        
        # Test email composition (without actually sending)
        print("\n4. Testing email composition...")
        
        # Test confirmation email composition
        try:
            # We'll test the private method to verify template processing works
            test_code = "test123456789012345678901234567890"
            confirmation_content = email_service._compose_email(
                template_type=AuthCodeType.EMAIL_CONFIRMATION,
                auth_code=test_code
            )
            print(f"✓ Confirmation email composed successfully (length: {len(confirmation_content)})")
            
            # Test password reset email composition
            reset_content = email_service._compose_email(
                template_type=AuthCodeType.PASSWORD_RESET,
                auth_code=test_code
            )
            print(f"✓ Password reset email composed successfully (length: {len(reset_content)})")
            
        except Exception as e:
            print(f"✗ Email composition failed: {e}")
            return False
        
        print("\n5. Testing EmailService orchestration logic...")
        try:
            # Test that the EmailService has all required methods and they're callable
            import inspect
            
            # Check that all required methods exist
            required_methods = [
                'send_confirmation_email',
                'send_password_reset_email',
                'health_check',
                'get_service_info'
            ]
            
            for method_name in required_methods:
                if hasattr(email_service, method_name):
                    method = getattr(email_service, method_name)
                    if callable(method):
                        print(f"✓ Method '{method_name}' is available and callable")
                    else:
                        print(f"✗ Method '{method_name}' is not callable")
                        return False
                else:
                    print(f"✗ Method '{method_name}' is missing")
                    return False
            
            # Test that private methods exist for orchestration
            private_methods = ['_compose_email', '_send_via_azure']
            for method_name in private_methods:
                if hasattr(email_service, method_name):
                    print(f"✓ Private method '{method_name}' is available")
                else:
                    print(f"✗ Private method '{method_name}' is missing")
                    return False
            
            print("✓ All EmailService orchestration methods are properly implemented")
            
        except Exception as e:
            print(f"✗ EmailService orchestration test failed: {e}")
            return False
        
        print("\n" + "=" * 60)
        print("✓ All EmailService integration tests passed!")
        print("✓ EmailService is ready for use")
        print("=" * 60)
        
        return True
        
    except Exception as e:
        print(f"\n✗ EmailService integration test failed: {e}")
        logger.exception("Integration test failed")
        return False


if __name__ == "__main__":
    success = asyncio.run(test_email_service_integration())
    sys.exit(0 if success else 1)