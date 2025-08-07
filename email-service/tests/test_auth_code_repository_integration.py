"""Integration tests for AuthCodeRepository with real bcrypt operations."""

import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import Mock
import uuid

from app.models.auth_code import AuthCode, AuthCodeType
from app.repositories.auth_code_repository import AuthCodeRepository


class TestAuthCodeRepositoryIntegration:
    """Integration test cases for AuthCodeRepository with real bcrypt."""
    
    @pytest.fixture
    def mock_supabase_client(self):
        """Create a mock Supabase client."""
        return Mock()
    
    @pytest.fixture
    def repository(self, mock_supabase_client):
        """Create a repository instance with mocked client."""
        return AuthCodeRepository(supabase_client=mock_supabase_client)
    
    def test_bcrypt_hash_and_verify_integration(self, repository):
        """Test that bcrypt hashing and verification work correctly together."""
        plain_codes = [
            "ABC123DEF456",
            "simple123",
            "Complex!@#$%^&*()Password123",
            "short",  # Short code
            "🔐🔑🗝️",  # Unicode characters
        ]
        
        for plain_code in plain_codes:
            # Hash the code
            hashed = repository._hash_code(plain_code)
            
            # Verify it's different from original
            assert hashed != plain_code
            assert len(hashed) > 0
            
            # Verify it can be verified correctly
            assert repository._verify_code(plain_code, hashed) is True
            
            # Verify wrong codes fail
            assert repository._verify_code(plain_code + "wrong", hashed) is False
            assert repository._verify_code("completely_different", hashed) is False
    
    def test_multiple_hashes_of_same_code_are_different(self, repository):
        """Test that hashing the same code multiple times produces different hashes."""
        plain_code = "ABC123DEF456"
        
        hash1 = repository._hash_code(plain_code)
        hash2 = repository._hash_code(plain_code)
        hash3 = repository._hash_code(plain_code)
        
        # All hashes should be different (due to salt)
        assert hash1 != hash2
        assert hash2 != hash3
        assert hash1 != hash3
        
        # But all should verify correctly
        assert repository._verify_code(plain_code, hash1) is True
        assert repository._verify_code(plain_code, hash2) is True
        assert repository._verify_code(plain_code, hash3) is True
    
    def test_store_and_retrieve_workflow(self, repository, mock_supabase_client):
        """Test the complete workflow of storing and retrieving a code."""
        # Create test auth code
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
        
        plain_code = "ABC123DEF456"
        
        # Mock successful storage
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.insert.return_value.execute.return_value.data = [{"id": auth_code.id}]
        
        # Store the code
        result = repository.store_auth_code(auth_code, plain_code)
        assert result is True
        
        # Verify the insert was called with hashed code
        insert_call_args = mock_table.insert.call_args[0][0]
        assert insert_call_args['code'] != plain_code  # Should be hashed
        assert len(insert_call_args['code']) > 0
        
        # Mock retrieval with the hashed code
        stored_hash = insert_call_args['code']
        mock_data = {
            "id": auth_code.id,
            "code": stored_hash,
            "user_id": auth_code.user_id,
            "type": auth_code.type if isinstance(auth_code.type, str) else auth_code.type.value,
            "created_at": auth_code.created_at.isoformat(),
            "expires_at": auth_code.expires_at.isoformat(),
            "is_used": False,
            "used_at": None
        }
        
        mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [mock_data]
        
        # Retrieve the code
        retrieved = repository.get_auth_code_by_code(plain_code, AuthCodeType.EMAIL_CONFIRMATION)
        
        assert retrieved is not None
        assert retrieved.id == auth_code.id
        assert retrieved.user_id == auth_code.user_id
        assert retrieved.type == auth_code.type
    
    def test_hash_code_error_handling(self, repository):
        """Test error handling in code hashing."""
        from app.repositories.auth_code_repository import AuthCodeRepositoryError
        
        # Test with None (should raise error)
        with pytest.raises(AuthCodeRepositoryError):
            repository._hash_code(None)
        
        # Test with empty string - this should work fine, just hash an empty string
        # Empty string is a valid input for bcrypt
        result = repository._hash_code("")
        assert len(result) > 0
        assert repository._verify_code("", result) is True
    
    def test_verify_code_error_handling(self, repository):
        """Test error handling in code verification."""
        valid_hash = repository._hash_code("test123")
        
        # Test with None values
        assert repository._verify_code(None, valid_hash) is False
        assert repository._verify_code("test123", None) is False
        
        # Test with empty strings
        assert repository._verify_code("", valid_hash) is False
        assert repository._verify_code("test123", "") is False
        
        # Test with invalid hash format
        assert repository._verify_code("test123", "not_a_valid_hash") is False