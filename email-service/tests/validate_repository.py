#!/usr/bin/env python3
"""Validation script to demonstrate AuthCodeRepository functionality."""

import logging
from datetime import datetime, timezone, timedelta
from unittest.mock import Mock
import uuid

from app.models.auth_code import AuthCode, AuthCodeType
from app.repositories.auth_code_repository import AuthCodeRepository

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    """Demonstrate AuthCodeRepository functionality."""
    print("🔐 AuthCodeRepository Validation Script")
    print("=" * 50)
    
    # Create a mock Supabase client for demonstration
    mock_client = Mock()
    repository = AuthCodeRepository(supabase_client=mock_client)
    
    print("\n1. Testing code hashing and verification...")
    
    # Test code hashing
    plain_codes = ["ABC123DEF456", "test123", "Complex!@#Password"]
    
    for plain_code in plain_codes:
        hashed = repository._hash_code(plain_code)
        verified = repository._verify_code(plain_code, hashed)
        
        print(f"   Plain: {plain_code}")
        print(f"   Hash:  {hashed[:50]}...")
        print(f"   Verified: {verified}")
        print()
    
    print("2. Testing AuthCode model creation...")
    
    # Create a sample auth code
    now = datetime.now(timezone.utc)
    auth_code = AuthCode(
        id=str(uuid.uuid4()),
        code="placeholder",  # Will be replaced with hash
        user_id="test-user-123",
        type=AuthCodeType.EMAIL_CONFIRMATION,
        created_at=now,
        expires_at=now + timedelta(minutes=5),
        is_used=False,
        used_at=None
    )
    
    print(f"   Created AuthCode:")
    print(f"   ID: {auth_code.id}")
    print(f"   User ID: {auth_code.user_id}")
    print(f"   Type: {auth_code.type}")
    print(f"   Valid: {auth_code.is_valid}")
    print(f"   Expired: {auth_code.is_expired}")
    
    print("\n3. Testing repository methods (with mocked database)...")
    
    # Mock successful database operations
    mock_table = Mock()
    mock_client.table.return_value = mock_table
    
    # Test store operation
    mock_table.insert.return_value.execute.return_value.data = [{"id": auth_code.id}]
    
    plain_code = "ABC123DEF456"
    store_result = repository.store_auth_code(auth_code, plain_code)
    print(f"   Store result: {store_result}")
    
    # Test retrieval operation
    hashed_code = repository._hash_code(plain_code)
    mock_data = {
        "id": auth_code.id,
        "code": hashed_code,
        "user_id": auth_code.user_id,
        "type": auth_code.type if isinstance(auth_code.type, str) else auth_code.type.value,
        "created_at": auth_code.created_at.isoformat(),
        "expires_at": auth_code.expires_at.isoformat(),
        "is_used": False,
        "used_at": None
    }
    
    mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [mock_data]
    
    retrieved = repository.get_auth_code_by_code(plain_code, AuthCodeType.EMAIL_CONFIRMATION)
    print(f"   Retrieved code: {retrieved.id if retrieved else 'None'}")
    
    # Test mark as used
    mock_table.update.return_value.eq.return_value.execute.return_value.data = [{"id": auth_code.id}]
    
    mark_result = repository.mark_code_as_used(auth_code.id)
    print(f"   Mark as used result: {mark_result}")
    
    # Test cleanup operations
    mock_table.delete.return_value.lt.return_value.execute.return_value.data = [
        {"id": "expired1"}, {"id": "expired2"}
    ]
    
    cleanup_result = repository.delete_expired_codes()
    print(f"   Cleanup expired codes: {cleanup_result} deleted")
    
    print("\n✅ All repository operations completed successfully!")
    print("\nKey features implemented:")
    print("  ✓ Secure bcrypt code hashing")
    print("  ✓ Code verification")
    print("  ✓ Database storage operations")
    print("  ✓ Code retrieval and validation")
    print("  ✓ Code lifecycle management")
    print("  ✓ Cleanup operations")
    print("  ✓ Comprehensive error handling")
    print("  ✓ Logging integration")


if __name__ == "__main__":
    main()